#!/usr/bin/env python3
"""
Export the cumulative permissions of multiple IAM groups from one AWS account,
then recreate them on a target IAM group in another account.

The script exports managed-policy and inline-policy documents. During apply, it
combines all statements into customer-managed "bundle" policies in the target
account. This avoids trying to attach source-account customer-managed policy
ARNs, which are not attachable in another account.

Examples:
  python migrate_iam_group_permissions.py export \
      --source-profile pck_prod \
      --source-groups group-a group-b group-c \
      --output ap-ai-permissions.json

  python migrate_iam_group_permissions.py apply \
      --target-profile pck_stg \
      --input ap-ai-permissions.json \
      --target-group ap-ai \
      --rewrite-account-id \
      --dry-run

  python migrate_iam_group_permissions.py apply \
      --target-profile pck_stg \
      --input ap-ai-permissions.json \
      --target-group ap-ai \
      --rewrite-account-id
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Sequence, Tuple
from urllib.parse import unquote

import boto3
from botocore.exceptions import BotoCoreError, ClientError, ProfileNotFound

POLICY_VERSION = "2012-10-17"
MANAGED_POLICY_CHAR_LIMIT = 6144
GROUP_MANAGED_POLICY_LIMIT = 10


class MigrationError(RuntimeError):
    """Raised for a migration-specific error."""


def compact_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True)


def policy_size(document: Dict[str, Any]) -> int:
    """Approximate IAM's non-whitespace character count."""
    return len(compact_json(document))


def normalize_policy_document(document: Any) -> Dict[str, Any]:
    """Return a policy document as a Python dictionary.

    Boto3 normally decodes IAM policy documents automatically. This also handles
    URL-encoded/string documents for compatibility with older callers.
    """
    if isinstance(document, dict):
        return document
    if not isinstance(document, str):
        raise MigrationError(f"Unexpected policy document type: {type(document)!r}")

    candidates = [document, unquote(document)]
    for candidate in candidates:
        try:
            parsed = json.loads(candidate)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            continue
    raise MigrationError("Could not decode an IAM policy document as JSON")


def make_session(profile_name: str) -> boto3.Session:
    return boto3.Session(profile_name=profile_name)


def caller_identity(session: boto3.Session) -> Tuple[str, str]:
    identity = session.client("sts").get_caller_identity()
    return identity["Account"], identity["Arn"]


def paginate(client: Any, operation: str, result_key: str, **kwargs: Any) -> Iterable[Any]:
    paginator = client.get_paginator(operation)
    for page in paginator.paginate(**kwargs):
        yield from page.get(result_key, [])


def get_managed_policy_document(iam: Any, policy_arn: str) -> Tuple[Dict[str, Any], str, str]:
    policy = iam.get_policy(PolicyArn=policy_arn)["Policy"]
    version_id = policy["DefaultVersionId"]
    document = iam.get_policy_version(
        PolicyArn=policy_arn,
        VersionId=version_id,
    )["PolicyVersion"]["Document"]
    managed_type = "AWS" if policy_arn.split(":")[4] == "aws" else "Customer"
    return normalize_policy_document(document), version_id, managed_type


def export_permissions(source_profile: str, source_groups: Sequence[str], output: Path) -> None:
    session = make_session(source_profile)
    source_account_id, source_principal_arn = caller_identity(session)
    iam = session.client("iam")

    exported: List[Dict[str, Any]] = []
    managed_by_arn: Dict[str, Dict[str, Any]] = {}

    for group_name in source_groups:
        # Fail early with a clear error if the group is missing or inaccessible.
        iam.get_group(GroupName=group_name, MaxItems=1)

        for attached in paginate(
            iam,
            "list_attached_group_policies",
            "AttachedPolicies",
            GroupName=group_name,
        ):
            arn = attached["PolicyArn"]
            if arn not in managed_by_arn:
                document, version_id, managed_type = get_managed_policy_document(iam, arn)
                item = {
                    "origin": "managed",
                    "managed_type": managed_type,
                    "policy_name": attached["PolicyName"],
                    "policy_arn": arn,
                    "default_version_id": version_id,
                    "source_groups": [group_name],
                    "document": document,
                }
                managed_by_arn[arn] = item
                exported.append(item)
            elif group_name not in managed_by_arn[arn]["source_groups"]:
                managed_by_arn[arn]["source_groups"].append(group_name)

        for inline_name in paginate(
            iam,
            "list_group_policies",
            "PolicyNames",
            GroupName=group_name,
        ):
            response = iam.get_group_policy(GroupName=group_name, PolicyName=inline_name)
            exported.append(
                {
                    "origin": "inline",
                    "managed_type": None,
                    "policy_name": inline_name,
                    "policy_arn": None,
                    "source_groups": [group_name],
                    "document": normalize_policy_document(response["PolicyDocument"]),
                }
            )

    payload = {
        "schema_version": 1,
        "source_profile": source_profile,
        "source_account_id": source_account_id,
        "source_principal_arn": source_principal_arn,
        "source_groups": list(source_groups),
        "policies": exported,
    }
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    managed_count = sum(1 for p in exported if p["origin"] == "managed")
    inline_count = sum(1 for p in exported if p["origin"] == "inline")
    print(f"Exported {managed_count} unique managed policies and {inline_count} inline policies")
    print(f"Source account: {source_account_id}")
    print(f"Output: {output}")


def rewrite_account_id(value: Any, source_account_id: str, target_account_id: str) -> Any:
    """Recursively replace the source account ID in all policy string values."""
    if isinstance(value, dict):
        return {k: rewrite_account_id(v, source_account_id, target_account_id) for k, v in value.items()}
    if isinstance(value, list):
        return [rewrite_account_id(v, source_account_id, target_account_id) for v in value]
    if isinstance(value, str):
        return value.replace(source_account_id, target_account_id)
    return value


def extract_statements(document: Dict[str, Any]) -> List[Dict[str, Any]]:
    statements = document.get("Statement", [])
    if isinstance(statements, dict):
        statements = [statements]
    if not isinstance(statements, list):
        raise MigrationError("Policy Statement must be an object or an array")

    result: List[Dict[str, Any]] = []
    for statement in statements:
        if not isinstance(statement, dict):
            raise MigrationError("Each policy Statement entry must be an object")
        statement_copy = copy.deepcopy(statement)
        # Sid has no permission semantics. Removing it avoids duplicate Sid values
        # when statements from multiple policies are placed in one bundle.
        statement_copy.pop("Sid", None)
        result.append(statement_copy)
    return result


def deduplicate_statements(statements: Iterable[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen: set[str] = set()
    result: List[Dict[str, Any]] = []
    for statement in statements:
        key = compact_json(statement)
        if key not in seen:
            seen.add(key)
            result.append(statement)
    return result


def pack_statements(statements: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Pack statements into policy documents under IAM's 6,144-char limit."""
    bundles: List[Dict[str, Any]] = []
    current: List[Dict[str, Any]] = []

    for statement in statements:
        candidate = {"Version": POLICY_VERSION, "Statement": current + [statement]}
        if policy_size(candidate) <= MANAGED_POLICY_CHAR_LIMIT:
            current.append(statement)
            continue

        if not current:
            raise MigrationError(
                "A single policy statement exceeds the IAM managed-policy size limit; "
                "split that statement manually before migration."
            )

        bundles.append({"Version": POLICY_VERSION, "Statement": current})
        current = [statement]
        single = {"Version": POLICY_VERSION, "Statement": current}
        if policy_size(single) > MANAGED_POLICY_CHAR_LIMIT:
            raise MigrationError(
                "A single policy statement exceeds the IAM managed-policy size limit; "
                "split that statement manually before migration."
            )

    if current:
        bundles.append({"Version": POLICY_VERSION, "Statement": current})
    return bundles


def sanitize_policy_name(name: str) -> str:
    sanitized = re.sub(r"[^A-Za-z0-9_+=,.@-]", "-", name)
    return sanitized[:128]


def get_policy_document(iam: Any, policy_arn: str) -> Dict[str, Any]:
    policy = iam.get_policy(PolicyArn=policy_arn)["Policy"]
    version = iam.get_policy_version(
        PolicyArn=policy_arn,
        VersionId=policy["DefaultVersionId"],
    )["PolicyVersion"]
    return normalize_policy_document(version["Document"])


def ensure_policy(
    iam: Any,
    policy_arn: str,
    policy_name: str,
    policy_path: str,
    document: Dict[str, Any],
    description: str,
    dry_run: bool,
) -> str:
    """Create or update a customer-managed policy and return its ARN."""
    try:
        current_document = get_policy_document(iam, policy_arn)
        exists = True
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") != "NoSuchEntity":
            raise
        current_document = None
        exists = False

    if not exists:
        if dry_run:
            print(f"[DRY-RUN] create policy {policy_arn} ({policy_size(document)} chars)")
            return policy_arn
        response = iam.create_policy(
            PolicyName=policy_name,
            Path=policy_path,
            PolicyDocument=compact_json(document),
            Description=description[:1000],
        )
        print(f"Created policy: {response['Policy']['Arn']}")
        return response["Policy"]["Arn"]

    if compact_json(current_document) == compact_json(document):
        print(f"Policy unchanged: {policy_arn}")
        return policy_arn

    if dry_run:
        print(f"[DRY-RUN] update policy {policy_arn} ({policy_size(document)} chars)")
        return policy_arn

    versions = iam.list_policy_versions(PolicyArn=policy_arn)["Versions"]
    if len(versions) >= 5:
        non_default = sorted(
            (v for v in versions if not v["IsDefaultVersion"]),
            key=lambda v: v["CreateDate"],
        )
        if not non_default:
            raise MigrationError(f"No deletable policy version found for {policy_arn}")
        iam.delete_policy_version(
            PolicyArn=policy_arn,
            VersionId=non_default[0]["VersionId"],
        )

    iam.create_policy_version(
        PolicyArn=policy_arn,
        PolicyDocument=compact_json(document),
        SetAsDefault=True,
    )
    print(f"Updated policy: {policy_arn}")
    return policy_arn


def ensure_group(iam: Any, group_name: str, dry_run: bool) -> None:
    try:
        iam.get_group(GroupName=group_name, MaxItems=1)
        print(f"Group exists: {group_name}")
    except ClientError as exc:
        if exc.response.get("Error", {}).get("Code") != "NoSuchEntity":
            raise
        if dry_run:
            print(f"[DRY-RUN] create group {group_name}")
        else:
            iam.create_group(GroupName=group_name)
            print(f"Created group: {group_name}")


def apply_permissions(
    target_profile: str,
    input_file: Path,
    target_group: str,
    policy_path: str,
    rewrite_ids: bool,
    preserve_aws_managed: bool,
    dry_run: bool,
) -> None:
    data = json.loads(input_file.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise MigrationError("Unsupported export schema version")

    source_account_id = str(data["source_account_id"])
    policies = data.get("policies", [])

    session = make_session(target_profile)
    target_account_id, target_principal_arn = caller_identity(session)
    iam = session.client("iam")

    if source_account_id == target_account_id:
        print("Warning: source and target account IDs are identical", file=sys.stderr)

    direct_aws_policy_arns: List[str] = []
    documents_to_bundle: List[Dict[str, Any]] = []

    for policy in policies:
        is_aws_managed = (
            policy.get("origin") == "managed" and policy.get("managed_type") == "AWS"
        )
        if preserve_aws_managed and is_aws_managed:
            direct_aws_policy_arns.append(policy["policy_arn"])
            continue

        document = normalize_policy_document(policy["document"])
        if rewrite_ids:
            document = rewrite_account_id(document, source_account_id, target_account_id)
        documents_to_bundle.append(document)

    direct_aws_policy_arns = sorted(set(direct_aws_policy_arns))

    statements: List[Dict[str, Any]] = []
    for document in documents_to_bundle:
        statements.extend(extract_statements(document))
    statements = deduplicate_statements(statements)
    bundles = pack_statements(statements)

    total_managed_attachments = len(direct_aws_policy_arns) + len(bundles)
    if total_managed_attachments > GROUP_MANAGED_POLICY_LIMIT:
        raise MigrationError(
            f"The migration requires {total_managed_attachments} managed-policy attachments, "
            f"but an IAM group supports at most {GROUP_MANAGED_POLICY_LIMIT}. "
            "Run without --preserve-aws-managed so AWS managed policies are also consolidated, "
            "or reduce/simplify the source permissions."
        )

    print(f"Source account: {source_account_id}")
    print(f"Target account: {target_account_id}")
    print(f"Target principal: {target_principal_arn}")
    print(f"Unique statements after deduplication: {len(statements)}")
    print(f"Bundle policies required: {len(bundles)}")
    print(f"AWS managed policies attached directly: {len(direct_aws_policy_arns)}")
    print(f"Account ID rewrite: {'enabled' if rewrite_ids else 'disabled'}")

    if not policy_path.startswith("/") or not policy_path.endswith("/"):
        raise MigrationError("--policy-path must start and end with '/', for example /ap-ai-migrated/")

    ensure_group(iam, target_group, dry_run)

    partition = target_principal_arn.split(":", 2)[1]
    policy_arns_to_attach: List[str] = []

    for index, bundle in enumerate(bundles, start=1):
        base_name = sanitize_policy_name(f"{target_group}-bundle-{index:02d}")
        policy_arn = f"arn:{partition}:iam::{target_account_id}:policy{policy_path}{base_name}"
        digest = hashlib.sha256(compact_json(bundle).encode("utf-8")).hexdigest()[:12]
        description = (
            f"Migrated cumulative IAM group permissions for {target_group}; "
            f"source account {source_account_id}; bundle {index}/{len(bundles)}; sha256 {digest}"
        )
        ensured_arn = ensure_policy(
            iam=iam,
            policy_arn=policy_arn,
            policy_name=base_name,
            policy_path=policy_path,
            document=bundle,
            description=description,
            dry_run=dry_run,
        )
        policy_arns_to_attach.append(ensured_arn)

    policy_arns_to_attach.extend(direct_aws_policy_arns)

    for policy_arn in policy_arns_to_attach:
        if dry_run:
            print(f"[DRY-RUN] attach {policy_arn} -> group/{target_group}")
        else:
            iam.attach_group_policy(GroupName=target_group, PolicyArn=policy_arn)
            print(f"Attached: {policy_arn}")

    print("Apply completed successfully" if not dry_run else "Dry run completed successfully")
    print("Note: unrelated policies already attached to the target group are not detached.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Export and migrate cumulative IAM group permissions across AWS accounts."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    export_parser = subparsers.add_parser("export", help="Export source IAM group permissions")
    export_parser.add_argument("--source-profile", required=True)
    export_parser.add_argument("--source-groups", nargs="+", required=True)
    export_parser.add_argument("--output", type=Path, default=Path("ap-ai-permissions.json"))

    apply_parser = subparsers.add_parser("apply", help="Apply exported permissions to target")
    apply_parser.add_argument("--target-profile", default="pck_stg")
    apply_parser.add_argument("--input", type=Path, required=True)
    apply_parser.add_argument("--target-group", default="ap-ai")
    apply_parser.add_argument("--policy-path", default="/ap-ai-migrated/")
    apply_parser.add_argument(
        "--rewrite-account-id",
        action="store_true",
        help="Replace the source account ID with the target account ID in policy string values.",
    )
    apply_parser.add_argument(
        "--preserve-aws-managed",
        action="store_true",
        help="Attach AWS managed policies directly instead of copying their current documents into bundles.",
    )
    apply_parser.add_argument("--dry-run", action="store_true")

    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "export":
            export_permissions(args.source_profile, args.source_groups, args.output)
        elif args.command == "apply":
            apply_permissions(
                target_profile=args.target_profile,
                input_file=args.input,
                target_group=args.target_group,
                policy_path=args.policy_path,
                rewrite_ids=args.rewrite_account_id,
                preserve_aws_managed=args.preserve_aws_managed,
                dry_run=args.dry_run,
            )
        return 0
    except ProfileNotFound as exc:
        print(f"AWS profile error: {exc}", file=sys.stderr)
    except ClientError as exc:
        error = exc.response.get("Error", {})
        print(
            f"AWS API error: {error.get('Code', 'Unknown')} - {error.get('Message', str(exc))}",
            file=sys.stderr,
        )
    except (BotoCoreError, OSError, json.JSONDecodeError, MigrationError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
