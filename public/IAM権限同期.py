#!/usr/bin/env python3
"""Incrementally copy selected IAM users/groups/policies from apai to pck_stg and pck_test.

Usage:
  python iam_user_sync.py            # DRY RUN (no changes)
  python iam_user_sync.py --apply    # make changes after typing APPLY

Uses existing AWS CLI profiles. No config file, manifest, log file, or report file is created.
"""

import argparse
import json
import logging
from typing import Any, Dict, List, Optional, Tuple

import boto3
from botocore.exceptions import ClientError, ProfileNotFound


# --------------------------- Edit these values ---------------------------
SOURCE_PROFILE = "apai"
TARGET_PROFILES = ["pck_stg", "pck_test"]

# Replace these examples with the exact IAM UserName values in the apai account.
USER_NAMES = ["YOUR_USER_1", "YOUR_USER_2", "YOUR_USER_3", "YOUR_USER_4"]

# IAM is a global AWS service. This region is used only for STS/profile sessions.
AWS_REGION = "ap-northeast-1"
# -------------------------------------------------------------------------


logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
LOG = logging.getLogger("iam-user-sync")


def canonical(document: Any) -> str:
    """Stable JSON representation for policy-document comparison."""
    return json.dumps(document, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def error_code(exc: ClientError) -> str:
    return exc.response.get("Error", {}).get("Code", "Unknown")


def is_missing(exc: ClientError) -> bool:
    return error_code(exc) in {"NoSuchEntity", "NoSuchEntityException"}


def items(iam: Any, operation: str, result_key: str, **kwargs: Any) -> List[Any]:
    paginator = iam.get_paginator(operation)
    result: List[Any] = []
    for page in paginator.paginate(**kwargs):
        result.extend(page.get(result_key, []))
    return result


def connect(profile: str) -> Tuple[Any, str]:
    """Create clients from an existing AWS CLI profile and return IAM + account ID."""
    session = boto3.Session(profile_name=profile, region_name=AWS_REGION)
    sts = session.client("sts", region_name=AWS_REGION)
    identity = sts.get_caller_identity()
    iam = session.client("iam", region_name="us-east-1")
    LOG.info("Profile %-12s -> account %s (%s)", profile, identity["Account"], identity["Arn"])
    return iam, identity["Account"]


def is_aws_managed_policy(policy_arn: str) -> bool:
    return ":iam::aws:policy/" in policy_arn


def target_policy_arn(source_arn: str, source_account: str, target_account: str) -> str:
    """Keep AWS policy ARNs; map source-account customer policy ARN to target account."""
    if is_aws_managed_policy(source_arn):
        return source_arn

    parts = source_arn.split(":", 5)
    if len(parts) != 6 or parts[0] != "arn" or parts[2] != "iam":
        raise RuntimeError(f"Unsupported IAM policy ARN: {source_arn}")
    if parts[4] != source_account:
        raise RuntimeError(
            "Found a customer-managed policy outside the source account; "
            f"cannot copy it automatically: {source_arn}"
        )
    parts[4] = target_account
    return ":".join(parts)


def get_policy_document(iam: Any, policy_arn: str) -> Dict[str, Any]:
    policy = iam.get_policy(PolicyArn=policy_arn)["Policy"]
    version = iam.get_policy_version(
        PolicyArn=policy_arn,
        VersionId=policy["DefaultVersionId"],
    )["PolicyVersion"]
    return {
        "PolicyName": policy["PolicyName"],
        "Path": policy["Path"],
        "Description": policy.get("Description", ""),
        "Document": version["Document"],
    }


def get_attached_policies(iam: Any, entity_type: str, name: str) -> List[Dict[str, str]]:
    if entity_type == "group":
        return items(iam, "list_attached_group_policies", "AttachedPolicies", GroupName=name)
    return items(iam, "list_attached_user_policies", "AttachedPolicies", UserName=name)


def get_inline_policies(iam: Any, entity_type: str, name: str) -> Dict[str, Any]:
    if entity_type == "group":
        names = items(iam, "list_group_policies", "PolicyNames", GroupName=name)
        return {
            policy_name: iam.get_group_policy(
                GroupName=name, PolicyName=policy_name
            )["PolicyDocument"]
            for policy_name in names
        }

    names = items(iam, "list_user_policies", "PolicyNames", UserName=name)
    return {
        policy_name: iam.get_user_policy(
            UserName=name, PolicyName=policy_name
        )["PolicyDocument"]
        for policy_name in names
    }


def read_source(source_iam: Any, source_account: str) -> Dict[str, Any]:
    """Read the selected users, their groups, and all referenced policy documents."""
    manifest: Dict[str, Any] = {"users": {}, "groups": {}, "customer_policies": {}}
    group_names = set()
    policy_arns = set()

    for username in USER_NAMES:
        user = source_iam.get_user(UserName=username)["User"]
        user_groups = items(
            source_iam, "list_groups_for_user", "Groups", UserName=username
        )
        attached = get_attached_policies(source_iam, "user", username)
        inline = get_inline_policies(source_iam, "user", username)
        boundary = user.get("PermissionsBoundary")

        group_names.update(group["GroupName"] for group in user_groups)
        policy_arns.update(policy["PolicyArn"] for policy in attached)
        if boundary:
            policy_arns.add(boundary["PermissionsBoundaryArn"])

        manifest["users"][username] = {
            "Path": user["Path"],
            "Groups": sorted(group["GroupName"] for group in user_groups),
            "AttachedPolicies": attached,
            "InlinePolicies": inline,
            "PermissionsBoundary": boundary,
        }

    for group_name in sorted(group_names):
        group = source_iam.get_group(GroupName=group_name)["Group"]
        attached = get_attached_policies(source_iam, "group", group_name)
        inline = get_inline_policies(source_iam, "group", group_name)
        policy_arns.update(policy["PolicyArn"] for policy in attached)
        manifest["groups"][group_name] = {
            "Path": group["Path"],
            "AttachedPolicies": attached,
            "InlinePolicies": inline,
        }

    for policy_arn in sorted(policy_arns):
        if is_aws_managed_policy(policy_arn):
            continue
        target_policy_arn(policy_arn, source_account, source_account)  # validates ownership
        manifest["customer_policies"][policy_arn] = get_policy_document(
            source_iam, policy_arn
        )

    LOG.info(
        "Source read complete: %d users, %d groups, %d customer-managed policies",
        len(manifest["users"]),
        len(manifest["groups"]),
        len(manifest["customer_policies"]),
    )
    return manifest


def ensure_customer_policy(
    target_iam: Any,
    source_arn: str,
    policy_data: Dict[str, Any],
    source_account: str,
    target_account: str,
    apply: bool,
) -> Optional[str]:
    """Create missing customer policy, reuse identical policy, never overwrite a conflict."""
    target_arn = target_policy_arn(source_arn, source_account, target_account)

    try:
        existing = get_policy_document(target_iam, target_arn)
        if canonical(existing["Document"]) == canonical(policy_data["Document"]):
            LOG.info("Policy exists and matches: %s", target_arn)
            return target_arn

        LOG.warning("SKIP policy conflict (same ARN, different document): %s", target_arn)
        return None

    except ClientError as exc:
        if not is_missing(exc):
            raise

    if not apply:
        LOG.info("DRY RUN: create customer-managed policy %s", target_arn)
        return target_arn

    params = {
        "PolicyName": policy_data["PolicyName"],
        "Path": policy_data["Path"],
        "PolicyDocument": json.dumps(policy_data["Document"]),
    }
    if policy_data.get("Description"):
        params["Description"] = policy_data["Description"]

    target_iam.create_policy(**params)
    LOG.info("Created customer-managed policy: %s", target_arn)
    return target_arn


def ensure_group(target_iam: Any, group_name: str, path: str, apply: bool) -> Tuple[bool, bool]:
    """Return (usable, newly_created_or_would_be_created)."""
    try:
        existing = target_iam.get_group(GroupName=group_name)["Group"]
        if existing["Path"] != path:
            LOG.warning(
                "Group %s exists with Path %s (source Path %s); keeping target Path",
                group_name, existing["Path"], path,
            )
        else:
            LOG.info("Group exists: %s", group_name)
        return True, False
    except ClientError as exc:
        if not is_missing(exc):
            raise

    if not apply:
        LOG.info("DRY RUN: create group %s", group_name)
        return True, True

    target_iam.create_group(GroupName=group_name, Path=path)
    LOG.info("Created group: %s", group_name)
    return True, True


def ensure_user(target_iam: Any, username: str, path: str, apply: bool) -> Tuple[bool, bool]:
    """Return (usable, newly_created_or_would_be_created)."""
    try:
        existing = target_iam.get_user(UserName=username)["User"]
        if existing["Path"] != path:
            LOG.warning(
                "User %s exists with Path %s (source Path %s); keeping target Path",
                username, existing["Path"], path,
            )
        else:
            LOG.info("User exists; reusing: %s", username)
        return True, False
    except ClientError as exc:
        if not is_missing(exc):
            raise

    if not apply:
        LOG.info("DRY RUN: create user %s", username)
        return True, True

    target_iam.create_user(UserName=username, Path=path)
    LOG.info("Created user: %s", username)
    return True, True


def ensure_attached_policy(
    target_iam: Any,
    entity_type: str,
    entity_name: str,
    policy_arn: str,
    apply: bool,
    entity_is_new: bool,
) -> None:
    if entity_is_new and not apply:
        LOG.info("DRY RUN: attach %s to %s %s", policy_arn, entity_type, entity_name)
        return

    attached = get_attached_policies(target_iam, entity_type, entity_name)
    if any(policy["PolicyArn"] == policy_arn for policy in attached):
        return

    if not apply:
        LOG.info("DRY RUN: attach %s to %s %s", policy_arn, entity_type, entity_name)
        return

    if entity_type == "group":
        target_iam.attach_group_policy(GroupName=entity_name, PolicyArn=policy_arn)
    else:
        target_iam.attach_user_policy(UserName=entity_name, PolicyArn=policy_arn)
    LOG.info("Attached %s to %s %s", policy_arn, entity_type, entity_name)


def ensure_inline_policies(
    target_iam: Any,
    entity_type: str,
    entity_name: str,
    source_inline: Dict[str, Any],
    apply: bool,
    entity_is_new: bool,
) -> None:
    if entity_is_new and not apply:
        for policy_name in source_inline:
            LOG.info(
                "DRY RUN: add inline policy %s to %s %s",
                policy_name, entity_type, entity_name,
            )
        return

    target_inline = get_inline_policies(target_iam, entity_type, entity_name)
    for policy_name, document in source_inline.items():
        if policy_name in target_inline:
            if canonical(target_inline[policy_name]) != canonical(document):
                LOG.warning(
                    "SKIP inline policy conflict (not overwritten): %s / %s",
                    entity_name, policy_name,
                )
            continue

        if not apply:
            LOG.info(
                "DRY RUN: add inline policy %s to %s %s",
                policy_name, entity_type, entity_name,
            )
            continue

        serialized = json.dumps(document)
        if entity_type == "group":
            target_iam.put_group_policy(
                GroupName=entity_name,
                PolicyName=policy_name,
                PolicyDocument=serialized,
            )
        else:
            target_iam.put_user_policy(
                UserName=entity_name,
                PolicyName=policy_name,
                PolicyDocument=serialized,
            )
        LOG.info("Added inline policy %s to %s", policy_name, entity_name)


def ensure_user_groups(
    target_iam: Any,
    username: str,
    source_groups: List[str],
    user_is_new: bool,
    apply: bool,
) -> None:
    if user_is_new and not apply:
        for group_name in source_groups:
            LOG.info("DRY RUN: add user %s to group %s", username, group_name)
        return

    current = {
        group["GroupName"]
        for group in items(
            target_iam, "list_groups_for_user", "Groups", UserName=username
        )
    }
    for group_name in source_groups:
        if group_name in current:
            continue
        if not apply:
            LOG.info("DRY RUN: add user %s to group %s", username, group_name)
            continue
        target_iam.add_user_to_group(UserName=username, GroupName=group_name)
        LOG.info("Added user %s to group %s", username, group_name)


def ensure_boundary(
    target_iam: Any,
    username: str,
    source_boundary: Optional[Dict[str, Any]],
    source_account: str,
    target_account: str,
    policy_map: Dict[str, Optional[str]],
    apply: bool,
) -> None:
    if not source_boundary:
        return  # Do not remove a boundary that already exists in the target.

    source_arn = source_boundary["PermissionsBoundaryArn"]
    if is_aws_managed_policy(source_arn):
        expected_arn = source_arn
    else:
        expected_arn = policy_map.get(source_arn)
        if not expected_arn:
            LOG.warning(
                "SKIP boundary for %s because its customer-managed policy could not be created/reused",
                username,
            )
            return

    current = target_iam.get_user(UserName=username)["User"].get("PermissionsBoundary")

    if current:
        if current["PermissionsBoundaryArn"] != expected_arn:
            LOG.warning(
                "SKIP boundary conflict for %s (target boundary is kept): %s",
                username, current["PermissionsBoundaryArn"],
            )
        return

    if not apply:
        LOG.info("DRY RUN: set permissions boundary for %s to %s", username, expected_arn)
        return

    target_iam.put_user_permissions_boundary(
        UserName=username,
        PermissionsBoundary=expected_arn,
    )
    LOG.info("Set permissions boundary for %s", username)


def sync_target(
    manifest: Dict[str, Any],
    source_account: str,
    target_profile: str,
    apply: bool,
) -> None:
    target_iam, target_account = connect(target_profile)
    LOG.info("---- Syncing target profile %s ----", target_profile)

    # Create/reuse all referenced customer-managed policies first.
    policy_map: Dict[str, Optional[str]] = {}
    for source_arn, policy_data in manifest["customer_policies"].items():
        policy_map[source_arn] = ensure_customer_policy(
            target_iam,
            source_arn,
            policy_data,
            source_account,
            target_account,
            apply,
        )

    # Create/reuse groups before assigning any users.
    group_new: Dict[str, bool] = {}
    for group_name, group_data in manifest["groups"].items():
        usable, is_new = ensure_group(
            target_iam, group_name, group_data["Path"], apply
        )
        if not usable:
            raise RuntimeError(f"Target group is not usable: {group_name}")
        group_new[group_name] = is_new

    # Add missing group policies. Existing target policies are not removed.
    for group_name, group_data in manifest["groups"].items():
        for policy in group_data["AttachedPolicies"]:
            source_arn = policy["PolicyArn"]
            if source_arn in manifest["customer_policies"]:
                mapped_arn = policy_map.get(source_arn)
                if not mapped_arn:
                    continue  # Same-name target policy conflict; do not attach it.
            else:
                mapped_arn = source_arn  # AWS-managed policy ARN is shared across accounts.

            ensure_attached_policy(
                target_iam, "group", group_name, mapped_arn,
                apply, group_new[group_name],
            )

        ensure_inline_policies(
            target_iam, "group", group_name,
            group_data["InlinePolicies"], apply, group_new[group_name],
        )

    # Create/reuse users, add only missing memberships and user-level policies.
    for username, user_data in manifest["users"].items():
        _, user_is_new = ensure_user(
            target_iam, username, user_data["Path"], apply
        )

        ensure_user_groups(
            target_iam, username, user_data["Groups"],
            user_is_new, apply,
        )

        for policy in user_data["AttachedPolicies"]:
            source_arn = policy["PolicyArn"]
            if source_arn in manifest["customer_policies"]:
                mapped_arn = policy_map.get(source_arn)
                if not mapped_arn:
                    continue
            else:
                mapped_arn = source_arn

            ensure_attached_policy(
                target_iam, "user", username, mapped_arn,
                apply, user_is_new,
            )

        ensure_inline_policies(
            target_iam, "user", username,
            user_data["InlinePolicies"], apply, user_is_new,
        )

        if not (user_is_new and not apply):
            ensure_boundary(
                target_iam, username, user_data["PermissionsBoundary"],
                source_account, target_account, policy_map, apply,
            )
        elif user_data["PermissionsBoundary"]:
            source_boundary_arn = user_data["PermissionsBoundary"]["PermissionsBoundaryArn"]
            if is_aws_managed_policy(source_boundary_arn):
                expected_boundary_arn = source_boundary_arn
            else:
                expected_boundary_arn = policy_map.get(source_boundary_arn)
            if expected_boundary_arn:
                LOG.info(
                    "DRY RUN: set permissions boundary for %s to %s",
                    username, expected_boundary_arn,
                )
            else:
                LOG.warning(
                    "DRY RUN: skip boundary for %s because its policy has a conflict",
                    username,
                )

    LOG.info("---- Finished target profile %s ----", target_profile)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Incrementally copy selected IAM users and permissions between AWS profiles."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes. Without this flag, the script only performs a DRY RUN.",
    )
    args = parser.parse_args()

    if len(USER_NAMES) != 4 or any(name.startswith("YOUR_USER_") for name in USER_NAMES):
        parser.error("Edit USER_NAMES at the top of the script and enter the four real IAM user names.")

    try:
        source_iam, source_account = connect(SOURCE_PROFILE)
        LOG.info("Reading source users from profile %s", SOURCE_PROFILE)
        manifest = read_source(source_iam, source_account)

        if args.apply:
            print("\nThis will add missing IAM users/groups/policies to:", ", ".join(TARGET_PROFILES))
            print("Existing target permissions will be retained. Policy conflicts will be skipped.")
            if input("Type APPLY to continue: ").strip() != "APPLY":
                print("Cancelled; no changes made.")
                return 0
        else:
            LOG.info("DRY RUN mode: no IAM resources will be created or changed.")

        for profile in TARGET_PROFILES:
            sync_target(manifest, source_account, profile, args.apply)

        LOG.info("All target profiles processed.")
        if not args.apply:
            LOG.info("Review the console output. To make changes, run: python %s --apply", __file__)
        return 0

    except ProfileNotFound as exc:
        LOG.error("AWS CLI profile not found: %s", exc)
        return 1
    except ClientError as exc:
        LOG.error("AWS API error: %s (%s)", exc, error_code(exc))
        LOG.error("Check the profile credentials and IAM permissions, then retry.")
        return 1
    except Exception as exc:
        LOG.exception("Sync stopped: %s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
