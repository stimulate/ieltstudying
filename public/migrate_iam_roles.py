#!/usr/bin/env python3
"""
Export and copy ordinary IAM roles across AWS accounts.

Copies:
- Role name/path/description/max session duration/tags
- Trust policy
- AWS managed policy attachments
- Customer managed policies (created once and reused)
- Inline policies
- Permissions boundaries
- Optional EC2 instance profiles

Skips:
- Service-linked roles (/aws-service-role/)
- IAM Identity Center generated AWSReservedSSO_* roles
"""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import hashlib
import json
import re
import sys
import urllib.parse
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Set, Tuple

import boto3
from botocore.exceptions import ClientError, ProfileNotFound


SCHEMA_VERSION = 1


class MigrationError(RuntimeError):
    pass


def compact(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def pretty(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, default=str)


def normalize_document(document: Any) -> Dict[str, Any]:
    if isinstance(document, str):
        document = json.loads(urllib.parse.unquote(document))
    if not isinstance(document, dict):
        raise MigrationError("Unexpected IAM policy document type")
    document = copy.deepcopy(document)
    if isinstance(document.get("Statement"), dict):
        document["Statement"] = [document["Statement"]]
    return document


def canonical(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: canonical(value[k]) for k in sorted(value)}
    if isinstance(value, list):
        items = [canonical(v) for v in value]
        return sorted(items, key=compact)
    return value


def document_hash(document: Dict[str, Any]) -> str:
    value = compact(canonical(normalize_document(document))).encode()
    return hashlib.sha256(value).hexdigest()


def rewrite_account(value: Any, source_id: str, target_id: str) -> Any:
    if isinstance(value, dict):
        return {k: rewrite_account(v, source_id, target_id) for k, v in value.items()}
    if isinstance(value, list):
        return [rewrite_account(v, source_id, target_id) for v in value]
    if isinstance(value, str):
        return value.replace(source_id, target_id)
    return value


def session(profile: str) -> boto3.Session:
    try:
        return boto3.Session(profile_name=profile)
    except ProfileNotFound as exc:
        raise MigrationError(str(exc)) from exc


def identity(sess: boto3.Session) -> Tuple[str, str]:
    result = sess.client("sts").get_caller_identity()
    return str(result["Account"]), str(result["Arn"])


def pages(client: Any, operation: str, result_key: str, **kwargs: Any) -> Iterator[Any]:
    paginator = client.get_paginator(operation)
    for page in paginator.paginate(**kwargs):
        yield from page.get(result_key, [])


def skipped_role(name: str, path: str) -> Optional[str]:
    if path.startswith("/aws-service-role/"):
        return "service-linked role"
    if path.startswith("/aws-reserved/sso.amazonaws.com/") or name.startswith("AWSReservedSSO_"):
        return "IAM Identity Center generated role"
    return None


def policy_type(arn: str) -> str:
    return "aws" if ":iam::aws:policy/" in arn else "customer"


def export_managed_policy(iam: Any, arn: str) -> Dict[str, Any]:
    meta = iam.get_policy(PolicyArn=arn)["Policy"]
    version = iam.get_policy_version(
        PolicyArn=arn,
        VersionId=meta["DefaultVersionId"],
    )["PolicyVersion"]
    try:
        tags = list(pages(iam, "list_policy_tags", "Tags", PolicyArn=arn))
    except ClientError:
        tags = []
    return {
        "source_arn": arn,
        "name": meta["PolicyName"],
        "path": meta.get("Path", "/"),
        "description": meta.get("Description", ""),
        "document": normalize_document(version["Document"]),
        "tags": tags,
    }


def export_roles(
    source_profile: str,
    output: Path,
    include_regex: Optional[str],
    exclude_regex: Optional[str],
) -> None:
    sess = session(source_profile)
    source_id, principal = identity(sess)
    iam = sess.client("iam")
    include = re.compile(include_regex) if include_regex else None
    exclude = re.compile(exclude_regex) if exclude_regex else None

    roles: List[Dict[str, Any]] = []
    customer_policies: Dict[str, Dict[str, Any]] = {}
    skipped: List[Dict[str, str]] = []

    all_roles = list(pages(iam, "list_roles", "Roles"))
    print(f"Found {len(all_roles)} IAM roles in account {source_id}")

    for summary in all_roles:
        name = summary["RoleName"]
        path = summary.get("Path", "/")
        reason = skipped_role(name, path)
        if reason:
            skipped.append({"role": name, "path": path, "reason": reason})
            continue
        if include and not include.search(name):
            continue
        if exclude and exclude.search(name):
            continue

        role = iam.get_role(RoleName=name)["Role"]
        tags = list(pages(iam, "list_role_tags", "Tags", RoleName=name))

        attached: List[Dict[str, str]] = []
        for item in pages(
            iam, "list_attached_role_policies", "AttachedPolicies", RoleName=name
        ):
            arn = item["PolicyArn"]
            ptype = policy_type(arn)
            attached.append({"arn": arn, "name": item["PolicyName"], "type": ptype})
            if ptype == "customer" and arn not in customer_policies:
                customer_policies[arn] = export_managed_policy(iam, arn)

        inline: List[Dict[str, Any]] = []
        for policy_name in pages(iam, "list_role_policies", "PolicyNames", RoleName=name):
            result = iam.get_role_policy(RoleName=name, PolicyName=policy_name)
            inline.append({
                "name": policy_name,
                "document": normalize_document(result["PolicyDocument"]),
            })

        boundary = role.get("PermissionsBoundary")
        boundary_data = None
        if boundary:
            arn = boundary["PermissionsBoundaryArn"]
            ptype = policy_type(arn)
            boundary_data = {"arn": arn, "type": ptype}
            if ptype == "customer" and arn not in customer_policies:
                customer_policies[arn] = export_managed_policy(iam, arn)

        profiles = [
            {"name": p["InstanceProfileName"], "path": p.get("Path", "/")}
            for p in pages(
                iam,
                "list_instance_profiles_for_role",
                "InstanceProfiles",
                RoleName=name,
            )
        ]

        roles.append({
            "name": name,
            "path": role.get("Path", "/"),
            "description": role.get("Description", ""),
            "max_session_duration": int(role.get("MaxSessionDuration", 3600)),
            "trust_policy": normalize_document(role["AssumeRolePolicyDocument"]),
            "tags": tags,
            "attached_policies": attached,
            "inline_policies": inline,
            "permissions_boundary": boundary_data,
            "instance_profiles": profiles,
        })
        print(f"Exported: {name}")

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "exported_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "source_profile": source_profile,
        "source_account_id": source_id,
        "source_principal_arn": principal,
        "roles": roles,
        "customer_managed_policies": list(customer_policies.values()),
        "skipped_roles": skipped,
    }
    output.write_text(pretty(manifest), encoding="utf-8")
    print(f"\nEligible roles exported: {len(roles)}")
    print(f"Customer managed policies exported: {len(customer_policies)}")
    print(f"Special roles skipped: {len(skipped)}")
    print(f"Manifest: {output}")


def partition(arn: str) -> str:
    return arn.split(":")[1]


def target_policy_arn(policy: Dict[str, Any], account_id: str, part: str) -> str:
    return f"arn:{part}:iam::{account_id}:policy{policy.get('path', '/')}{policy['name']}"


def get_policy_document(iam: Any, arn: str) -> Dict[str, Any]:
    meta = iam.get_policy(PolicyArn=arn)["Policy"]
    version = iam.get_policy_version(
        PolicyArn=arn, VersionId=meta["DefaultVersionId"]
    )["PolicyVersion"]
    return normalize_document(version["Document"])


def delete_oldest_nondefault_version(iam: Any, arn: str, dry_run: bool) -> None:
    versions = iam.list_policy_versions(PolicyArn=arn)["Versions"]
    if len(versions) < 5:
        return
    candidates = sorted(
        [v for v in versions if not v["IsDefaultVersion"]],
        key=lambda x: x["CreateDate"],
    )
    if not candidates:
        raise MigrationError(f"No removable version for {arn}")
    version_id = candidates[0]["VersionId"]
    print(f"  Delete old policy version {version_id}: {arn}")
    if not dry_run:
        iam.delete_policy_version(PolicyArn=arn, VersionId=version_id)


def ensure_customer_policy(
    iam: Any,
    item: Dict[str, Any],
    source_id: str,
    target_id: str,
    part: str,
    rewrite_ids: bool,
    update_existing: bool,
    dry_run: bool,
) -> str:
    arn = target_policy_arn(item, target_id, part)
    expected = normalize_document(item["document"])
    if rewrite_ids:
        expected = rewrite_account(expected, source_id, target_id)

    try:
        actual = get_policy_document(iam, arn)
        exists = True
    except ClientError as exc:
        if exc.response["Error"]["Code"] != "NoSuchEntity":
            raise
        exists = False
        actual = {}

    if not exists:
        print(f"Create customer managed policy: {arn}")
        if not dry_run:
            kwargs: Dict[str, Any] = {
                "PolicyName": item["name"],
                "Path": item.get("path", "/"),
                "Description": item.get("description", "")[:1000],
                "PolicyDocument": compact(expected),
            }
            if item.get("tags"):
                kwargs["Tags"] = item["tags"]
            iam.create_policy(**kwargs)
        return arn

    if document_hash(actual) == document_hash(expected):
        print(f"Policy unchanged: {arn}")
        return arn

    if not update_existing:
        raise MigrationError(
            f"Target policy exists with different content: {arn}. "
            "Review it, then rerun with --update-existing-policies."
        )

    print(f"Update customer managed policy: {arn}")
    if not dry_run:
        delete_oldest_nondefault_version(iam, arn, dry_run=False)
        iam.create_policy_version(
            PolicyArn=arn,
            PolicyDocument=compact(expected),
            SetAsDefault=True,
        )
    return arn


def role_exists(iam: Any, name: str) -> bool:
    try:
        iam.get_role(RoleName=name)
        return True
    except ClientError as exc:
        if exc.response["Error"]["Code"] == "NoSuchEntity":
            return False
        raise


def mapped_policy_arn(item: Dict[str, Any], mapping: Dict[str, str]) -> str:
    return item["arn"] if item["type"] == "aws" else mapping[item["arn"]]


def ensure_instance_profiles(
    iam: Any,
    role_name: str,
    profiles: List[Dict[str, str]],
    dry_run: bool,
) -> None:
    for profile in profiles:
        name = profile["name"]
        try:
            result = iam.get_instance_profile(InstanceProfileName=name)
            roles = result["InstanceProfile"].get("Roles", [])
        except ClientError as exc:
            if exc.response["Error"]["Code"] != "NoSuchEntity":
                raise
            roles = []
            print(f"  Create instance profile: {name}")
            if not dry_run:
                iam.create_instance_profile(
                    InstanceProfileName=name,
                    Path=profile.get("path", "/"),
                )

        current_names = {r["RoleName"] for r in roles}
        if role_name not in current_names:
            if current_names:
                raise MigrationError(
                    f"Instance profile {name} already contains {sorted(current_names)}"
                )
            print(f"  Add role to instance profile: {name}")
            if not dry_run:
                iam.add_role_to_instance_profile(
                    InstanceProfileName=name,
                    RoleName=role_name,
                )


def apply_roles(
    target_profile: str,
    input_file: Path,
    rewrite_ids: bool,
    update_existing_policies: bool,
    copy_instance_profiles: bool,
    dry_run: bool,
) -> None:
    data = json.loads(input_file.read_text(encoding="utf-8"))
    if data.get("schema_version") != SCHEMA_VERSION:
        raise MigrationError("Unsupported manifest schema")

    source_id = str(data["source_account_id"])
    sess = session(target_profile)
    target_id, principal = identity(sess)
    if source_id == target_id:
        raise MigrationError("Source and target accounts are identical")
    iam = sess.client("iam")
    part = partition(principal)

    print(f"Source account: {source_id}")
    print(f"Target account: {target_id}")
    print(f"Target principal: {principal}")
    print(f"Roles: {len(data['roles'])}")
    print(f"Rewrite account ID: {rewrite_ids}")
    print(f"Dry run: {dry_run}\n")

    mapping: Dict[str, str] = {}
    for item in data.get("customer_managed_policies", []):
        mapping[item["source_arn"]] = ensure_customer_policy(
            iam,
            item,
            source_id,
            target_id,
            part,
            rewrite_ids,
            update_existing_policies,
            dry_run,
        )

    for role in data["roles"]:
        name = role["name"]
        trust = normalize_document(role["trust_policy"])
        if rewrite_ids:
            trust = rewrite_account(trust, source_id, target_id)

        boundary = role.get("permissions_boundary")
        boundary_arn = None
        if boundary:
            boundary_arn = (
                boundary["arn"] if boundary["type"] == "aws" else mapping[boundary["arn"]]
            )

        exists = role_exists(iam, name)
        print(f"\n{'Update' if exists else 'Create'} role: {name}")

        if not exists:
            if not dry_run:
                kwargs: Dict[str, Any] = {
                    "RoleName": name,
                    "Path": role.get("path", "/"),
                    "Description": role.get("description", "")[:1000],
                    "MaxSessionDuration": int(role.get("max_session_duration", 3600)),
                    "AssumeRolePolicyDocument": compact(trust),
                }
                if role.get("tags"):
                    kwargs["Tags"] = role["tags"]
                if boundary_arn:
                    kwargs["PermissionsBoundary"] = boundary_arn
                iam.create_role(**kwargs)
        else:
            print("  Update trust policy, description and max session duration")
            if not dry_run:
                iam.update_assume_role_policy(
                    RoleName=name,
                    PolicyDocument=compact(trust),
                )
                iam.update_role(
                    RoleName=name,
                    Description=role.get("description", "")[:1000],
                    MaxSessionDuration=int(role.get("max_session_duration", 3600)),
                )
                if boundary_arn:
                    iam.put_role_permissions_boundary(
                        RoleName=name,
                        PermissionsBoundary=boundary_arn,
                    )

            current_tags = {
                item["Key"]: item["Value"]
                for item in pages(iam, "list_role_tags", "Tags", RoleName=name)
            }
            expected_tags = {
                item["Key"]: item["Value"] for item in role.get("tags", [])
            }
            changed_tags = [
                {"Key": key, "Value": value}
                for key, value in expected_tags.items()
                if current_tags.get(key) != value
            ]
            if changed_tags:
                print(f"  Add/update tags: {[x['Key'] for x in changed_tags]}")
                if not dry_run:
                    iam.tag_role(RoleName=name, Tags=changed_tags)

        current_attached = {
            x["PolicyArn"]
            for x in pages(
                iam,
                "list_attached_role_policies",
                "AttachedPolicies",
                RoleName=name,
            )
        } if exists or not dry_run else set()

        for item in role.get("attached_policies", []):
            arn = mapped_policy_arn(item, mapping)
            if arn not in current_attached:
                print(f"  Attach: {arn}")
                if not dry_run:
                    iam.attach_role_policy(RoleName=name, PolicyArn=arn)

        for inline in role.get("inline_policies", []):
            document = normalize_document(inline["document"])
            if rewrite_ids:
                document = rewrite_account(document, source_id, target_id)
            print(f"  Put inline policy: {inline['name']}")
            if not dry_run:
                iam.put_role_policy(
                    RoleName=name,
                    PolicyName=inline["name"],
                    PolicyDocument=compact(document),
                )

        if copy_instance_profiles:
            ensure_instance_profiles(
                iam,
                name,
                role.get("instance_profiles", []),
                dry_run,
            )

    print("\nApply completed." if not dry_run else "\nDry run completed.")


def verify_roles(
    target_profile: str,
    input_file: Path,
    rewrite_ids: bool,
    report: Path,
) -> None:
    data = json.loads(input_file.read_text(encoding="utf-8"))
    source_id = str(data["source_account_id"])
    sess = session(target_profile)
    target_id, principal = identity(sess)
    iam = sess.client("iam")
    part = partition(principal)

    policy_map = {
        p["source_arn"]: target_policy_arn(p, target_id, part)
        for p in data.get("customer_managed_policies", [])
    }
    failures: List[Dict[str, Any]] = []

    for expected in data["roles"]:
        name = expected["name"]
        issues: List[Dict[str, Any]] = []
        try:
            actual = iam.get_role(RoleName=name)["Role"]
        except ClientError as exc:
            if exc.response["Error"]["Code"] == "NoSuchEntity":
                failures.append({"role": name, "issues": ["missing role"]})
                print(f"FAIL: {name} (missing)")
                continue
            raise

        expected_trust = normalize_document(expected["trust_policy"])
        if rewrite_ids:
            expected_trust = rewrite_account(expected_trust, source_id, target_id)
        if document_hash(expected_trust) != document_hash(actual["AssumeRolePolicyDocument"]):
            issues.append({"type": "trust_policy_mismatch"})

        expected_attached = {
            x["arn"] if x["type"] == "aws" else policy_map[x["arn"]]
            for x in expected.get("attached_policies", [])
        }
        actual_attached = {
            x["PolicyArn"]
            for x in pages(
                iam,
                "list_attached_role_policies",
                "AttachedPolicies",
                RoleName=name,
            )
        }
        if expected_attached != actual_attached:
            issues.append({
                "type": "attached_policy_mismatch",
                "missing": sorted(expected_attached - actual_attached),
                "extra": sorted(actual_attached - expected_attached),
            })

        expected_inline: Dict[str, str] = {}
        for item in expected.get("inline_policies", []):
            doc = normalize_document(item["document"])
            if rewrite_ids:
                doc = rewrite_account(doc, source_id, target_id)
            expected_inline[item["name"]] = document_hash(doc)

        actual_inline: Dict[str, str] = {}
        for policy_name in pages(
            iam, "list_role_policies", "PolicyNames", RoleName=name
        ):
            doc = iam.get_role_policy(RoleName=name, PolicyName=policy_name)["PolicyDocument"]
            actual_inline[policy_name] = document_hash(doc)

        if expected_inline != actual_inline:
            issues.append({
                "type": "inline_policy_mismatch",
                "missing_or_changed": sorted(
                    n for n, h in expected_inline.items()
                    if actual_inline.get(n) != h
                ),
                "extra": sorted(set(actual_inline) - set(expected_inline)),
            })

        expected_metadata = {
            "path": expected.get("path", "/"),
            "description": expected.get("description", ""),
            "max_session_duration": int(expected.get("max_session_duration", 3600)),
        }
        actual_metadata = {
            "path": actual.get("Path", "/"),
            "description": actual.get("Description", ""),
            "max_session_duration": int(actual.get("MaxSessionDuration", 3600)),
        }
        if expected_metadata != actual_metadata:
            issues.append({
                "type": "role_metadata_mismatch",
                "expected": expected_metadata,
                "actual": actual_metadata,
            })

        expected_tags = {
            item["Key"]: item["Value"] for item in expected.get("tags", [])
        }
        actual_tags = {
            item["Key"]: item["Value"]
            for item in pages(iam, "list_role_tags", "Tags", RoleName=name)
        }
        if any(actual_tags.get(k) != v for k, v in expected_tags.items()):
            issues.append({
                "type": "role_tag_mismatch",
                "expected_tags": expected_tags,
                "actual_tags": actual_tags,
            })

        expected_boundary = expected.get("permissions_boundary")
        expected_boundary_arn = None
        if expected_boundary:
            expected_boundary_arn = (
                expected_boundary["arn"]
                if expected_boundary["type"] == "aws"
                else policy_map[expected_boundary["arn"]]
            )
        actual_boundary_arn = actual.get("PermissionsBoundary", {}).get(
            "PermissionsBoundaryArn"
        )
        if expected_boundary_arn != actual_boundary_arn:
            issues.append({
                "type": "permissions_boundary_mismatch",
                "expected": expected_boundary_arn,
                "actual": actual_boundary_arn,
            })

        if issues:
            failures.append({"role": name, "issues": issues})
            print(f"FAIL: {name} ({len(issues)} issue(s))")
        else:
            print(f"OK:   {name}")

    result = {
        "source_account_id": source_id,
        "target_account_id": target_id,
        "expected_roles": len(data["roles"]),
        "failed_roles": len(failures),
        "failures": failures,
    }
    report.write_text(pretty(result), encoding="utf-8")
    print(f"\nReport: {report}")
    if failures:
        raise MigrationError(f"Verification failed for {len(failures)} role(s)")
    print("VERIFIED: target roles match the export manifest.")


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Cross-account IAM role migration")
    commands = p.add_subparsers(dest="command", required=True)

    e = commands.add_parser("export")
    e.add_argument("--source-profile", required=True)
    e.add_argument("--output", type=Path, required=True)
    e.add_argument("--include-role-regex")
    e.add_argument("--exclude-role-regex")

    a = commands.add_parser("apply")
    a.add_argument("--target-profile", required=True)
    a.add_argument("--input", type=Path, required=True)
    a.add_argument("--rewrite-account-id", action="store_true")
    a.add_argument("--update-existing-policies", action="store_true")
    a.add_argument("--copy-instance-profiles", action="store_true")
    a.add_argument("--dry-run", action="store_true")

    v = commands.add_parser("verify")
    v.add_argument("--target-profile", required=True)
    v.add_argument("--input", type=Path, required=True)
    v.add_argument("--rewrite-account-id", action="store_true")
    v.add_argument("--report", type=Path, default=Path("iam-role-verification.json"))

    return p


def main() -> int:
    args = parser().parse_args()
    try:
        if args.command == "export":
            export_roles(
                args.source_profile,
                args.output,
                args.include_role_regex,
                args.exclude_role_regex,
            )
        elif args.command == "apply":
            apply_roles(
                args.target_profile,
                args.input,
                args.rewrite_account_id,
                args.update_existing_policies,
                args.copy_instance_profiles,
                args.dry_run,
            )
        else:
            verify_roles(
                args.target_profile,
                args.input,
                args.rewrite_account_id,
                args.report,
            )
        return 0
    except (MigrationError, ClientError, OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
