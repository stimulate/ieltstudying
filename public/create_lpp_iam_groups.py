"""Create/sync IAM Groups in lpp-test and lpp-prod, with preview by default.

Examples:
  python create_lpp_iam_groups.py --kms-mode custom-full
  python create_lpp_iam_groups.py --profiles lpp-test --kms-mode custom-full --apply
  python create_lpp_iam_groups.py --kms-mode custom-full --apply

IMPORTANT: custom-full creates a very broad customer-managed kms:* policy.
"""

import argparse
import json
import sys
from urllib.parse import unquote

import boto3
from botocore.exceptions import BotoCoreError, ClientError, ProfileNotFound

AWS_POLICIES = [
    "AmazonECS_FullAccess",
    "AmazonKinesisFirehoseFullAccess",
    "AWSCloudTrail_FullAccess",
    "AWSConfigUserAccess",
    "AWSSecurityHubFullAccess",
    "AmazonGuardDutyFullAccess_v2",  # Old policy cannot be newly attached.
    "AmazonEventBridgeFullAccess",
    "AmazonSNSFullAccess",
    "AmazonInspector2FullAccess_v2",
]

CUSTOM_KMS_NAME = "LPP_KMS_FullAccess"
CUSTOM_KMS_DOCUMENT = {
    "Version": "2012-10-17",
    "Statement": [{"Effect": "Allow", "Action": "kms:*", "Resource": "*"}],
}
MAX_MANAGED_POLICIES_PER_GROUP = 10


def get_group_policy_arns(iam, group_name):
    arns = set()
    for page in iam.get_paginator("list_attached_group_policies").paginate(
        GroupName=group_name
    ):
        arns.update(p["PolicyArn"] for p in page["AttachedPolicies"])
    return arns


def aws_policy_arns(partition):
    return [f"arn:{partition}:iam::aws:policy/{name}" for name in AWS_POLICIES]


def read_custom_policy(iam, arn):
    try:
        policy = iam.get_policy(PolicyArn=arn)["Policy"]
    except iam.exceptions.NoSuchEntityException:
        return False
    version = iam.get_policy_version(
        PolicyArn=arn, VersionId=policy["DefaultVersionId"]
    )["PolicyVersion"]["Document"]
    if isinstance(version, str):
        version = json.loads(unquote(version))
    if version != CUSTOM_KMS_DOCUMENT:
        raise ValueError(
            f"Existing policy {arn} has different permissions; refusing to overwrite."
        )
    return True


def inspect_account(profile, group_name, kms_mode):
    session = boto3.Session(profile_name=profile)
    sts = session.client("sts")
    iam = session.client("iam")
    identity = sts.get_caller_identity()
    account_id = identity["Account"]
    partition = identity["Arn"].split(":")[1]

    try:
        iam.get_group(GroupName=group_name)
        group_exists = True
        attached = get_group_policy_arns(iam, group_name)
    except iam.exceptions.NoSuchEntityException:
        group_exists = False
        attached = set()

    managed = aws_policy_arns(partition)
    for arn in managed:
        iam.get_policy(PolicyArn=arn)  # Fail early if AWS policy is unavailable.

    if kms_mode == "custom-full":
        kms_arn = f"arn:{partition}:iam::{account_id}:policy/{CUSTOM_KMS_NAME}"
        custom_exists = read_custom_policy(iam, kms_arn)
    else:
        kms_arn = f"arn:{partition}:iam::aws:policy/AWSKeyManagementServicePowerUser"
        iam.get_policy(PolicyArn=kms_arn)
        custom_exists = True

    wanted = set(managed + [kms_arn])
    if len(attached | wanted) > MAX_MANAGED_POLICIES_PER_GROUP:
        raise ValueError(
            f"Profile {profile}: group already has extra policies and would exceed "
            f"the {MAX_MANAGED_POLICIES_PER_GROUP}-policy IAM Group limit."
        )

    return {
        "profile": profile, "iam": iam, "account_id": account_id,
        "identity": identity["Arn"], "group_exists": group_exists,
        "attached": attached, "wanted": wanted,
        "kms_arn": kms_arn, "custom_exists": custom_exists,
    }


def apply_account(plan, group_name, kms_mode):
    iam = plan["iam"]
    if kms_mode == "custom-full" and not plan["custom_exists"]:
        iam.create_policy(
            PolicyName=CUSTOM_KMS_NAME,
            PolicyDocument=json.dumps(CUSTOM_KMS_DOCUMENT),
            Description="Broad KMS full access for approved LPP IAM Group users",
        )
        print("  CREATED customer-managed KMS policy")

    if not plan["group_exists"]:
        iam.create_group(GroupName=group_name)
        print(f"  CREATED group {group_name}")
    else:
        print(f"  EXISTS group {group_name}")

    for arn in sorted(plan["wanted"]):
        name = arn.rsplit("/", 1)[-1]
        if arn in plan["attached"]:
            print(f"  SKIP   {name} (already attached)")
            continue
        iam.attach_group_policy(GroupName=group_name, PolicyArn=arn)
        print(f"  ADDED  {name}")

    actual = get_group_policy_arns(iam, group_name)
    if not plan["wanted"].issubset(actual):
        raise RuntimeError("Verification failed: some required policies were not attached")
    print(f"  VERIFIED {len(plan['wanted'])}/{len(plan['wanted'])} required policies")


def main():
    parser = argparse.ArgumentParser(description="Manage LPP IAM Groups in two accounts")
    parser.add_argument("--profiles", nargs="+", choices=["lpp-test", "lpp-prod"],
                        default=["lpp-test", "lpp-prod"])
    parser.add_argument("--group", default="LPP-Operations",
                        help="IAM Group name (same in both accounts)")
    parser.add_argument("--kms-mode", required=True,
                        choices=["custom-full", "power-user"],
                        help="custom-full: create kms:* customer policy; "
                             "power-user: use AWS-managed weaker PowerUser policy")
    parser.add_argument("--apply", action="store_true",
                        help="Actually create/attach; default is read-only preview")
    args = parser.parse_args()

    if len(set(args.profiles)) != len(args.profiles):
        parser.error("Duplicate profile")

    print(f"IAM Group: {args.group}")
    print(f"KMS mode : {args.kms_mode}")
    if args.kms_mode == "custom-full":
        print("WARNING: custom KMS policy grants kms:* on Resource *; KMS key policies still apply.")

    # Preflight ALL accounts before ANY write.
    plans = [inspect_account(p, args.group, args.kms_mode) for p in args.profiles]
    if len({p["account_id"] for p in plans}) != len(plans):
        raise ValueError("Profiles resolve to the same AWS account; refusing to proceed")

    for p in plans:
        print(f"\nProfile: {p['profile']} | Account: {p['account_id']}")
        print(f"Caller : {p['identity']}")
        print(f"Group  : {'existing' if p['group_exists'] else 'will create'}")
        if args.kms_mode == "custom-full":
            print(f"KMS policy: {'existing' if p['custom_exists'] else 'will create'}")
        missing = p["wanted"] - p["attached"]
        print(f"To attach: {len(missing)} policies")
        for arn in sorted(missing):
            print("  +", arn.rsplit("/", 1)[-1])

    if not args.apply:
        print("\nPREVIEW ONLY. No AWS resources were modified. Use --apply after review.")
        return

    # Obtain explicit confirmation for each target account before writing to either.
    for p in plans:
        answer = input(
            f"Type AWS Account ID {p['account_id']} to confirm writes for "
            f"{p['profile']}: "
        ).strip()
        if answer != p["account_id"]:
            raise ValueError("Confirmation did not match. No changes made.")

    for p in plans:
        print(f"\nAPPLYING: {p['profile']} / {p['account_id']}")
        apply_account(p, args.group, args.kms_mode)
    print("\nDone. No IAM users were added to the groups.")


if __name__ == "__main__":
    try:
        main()
    except (BotoCoreError, ClientError, ProfileNotFound, ValueError,
            RuntimeError, EOFError, KeyboardInterrupt) as exc:
        print(f"\nERROR: {exc}", file=sys.stderr)
        sys.exit(1)
