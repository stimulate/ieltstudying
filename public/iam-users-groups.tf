variable "bill_viewer_users" {
  description = "IAM users who should be members of BillViewer."
  type        = set(string)
  default     = []
}

variable "developer_users" {
  description = "IAM users who should be members of Developer."
  type        = set(string)
  default     = []
}

variable "infra_engineer_users" {
  description = "IAM users who should be members of InfraEngineer."
  type        = set(string)
  default     = []
}

variable "terraform_state_bucket_name" {
  description = "Existing S3 bucket that stores Terraform state."
  type        = string
}

locals {
  all_iam_users = setunion(
    var.bill_viewer_users,
    var.developer_users,
    var.infra_engineer_users,
  )

  terraform_state_bucket_arn = "arn:aws:s3:::${var.terraform_state_bucket_name}"

  iam_user_groups = {
    for user_name in local.all_iam_users :
    user_name => compact([
      contains(var.bill_viewer_users, user_name) ? aws_iam_group.bill_viewer.name : null,
      contains(var.developer_users, user_name) ? aws_iam_group.developer.name : null,
      contains(var.infra_engineer_users, user_name) ? aws_iam_group.infra_engineer.name : null,
    ])
  }
}

resource "aws_iam_group" "bill_viewer" {
  name = "BillViewer"
}

resource "aws_iam_group" "administrator" {
  name = "Administrator"
}

resource "aws_iam_group" "developer" {
  name = "Developer"
}

resource "aws_iam_group" "infra_engineer" {
  name = "InfraEngineer"
}

resource "aws_iam_user" "users" {
  for_each = local.all_iam_users

  name          = each.value
  force_destroy = false

  tags = {
    Project     = "eol"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_user_group_membership" "users" {
  for_each = local.iam_user_groups

  user   = aws_iam_user.users[each.key].name
  groups = each.value
}

resource "aws_iam_group_policy_attachment" "bill_viewer_billing_read_only" {
  group      = aws_iam_group.bill_viewer.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBillingReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "administrator_access" {
  group      = aws_iam_group.administrator.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "developer_access" {
  statement {
    sid    = "AmplifyDeveloperOperations"
    effect = "Allow"

    actions = [
      "amplify:CreateDeployment",
      "amplify:GetApp",
      "amplify:GetBranch",
      "amplify:GetJob",
      "amplify:ListApps",
      "amplify:ListBranches",
      "amplify:ListJobs",
      "amplify:StartDeployment",
      "amplify:StartJob",
      "amplify:StopJob",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "S3ConsoleList"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetAccountPublicAccessBlock",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ApplicationBucketList"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]

    resources = [
      aws_s3_bucket.static.arn,
      aws_s3_bucket.uploads.arn,
    ]
  }

  statement {
    sid    = "ApplicationObjectAccess"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.static.arn}/*",
      "${aws_s3_bucket.uploads.arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontReadAndInvalidate"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:GetInvalidation",
      "cloudfront:ListDistributions",
      "cloudfront:ListInvalidations",
      "cloudfront:ListTagsForResource",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Route53ReadOnly"
    effect = "Allow"

    actions = [
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ACMReadOnly"
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "developer_access" {
  name        = "EolDevDeveloperAccess"
  description = "Developer permissions for EOL DEV application resources"
  policy      = data.aws_iam_policy_document.developer_access.json
}

resource "aws_iam_group_policy_attachment" "developer_access" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.developer_access.arn
}

data "aws_iam_policy_document" "infra_engineer_access" {
  statement {
    sid    = "ManageProjectServices"
    effect = "Allow"

    actions = [
      "acm:*",
      "amplify:*",
      "cloudfront:*",
      "route53:*",
      "s3:*",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ProtectTerraformStateBucket"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      local.terraform_state_bucket_arn,
      "${local.terraform_state_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "ReadIAMRolesForAmplify"
    effect = "Allow"

    actions = [
      "iam:GetRole",
      "iam:ListRoles",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PassAmplifyServiceRole"
    effect = "Allow"

    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.amplify_service.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["amplify.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "infra_engineer_access" {
  name        = "EolDevInfraEngineerAccess"
  description = "Infrastructure engineering permissions for EOL DEV services"
  policy      = data.aws_iam_policy_document.infra_engineer_access.json
}

resource "aws_iam_group_policy_attachment" "infra_engineer_access" {
  group      = aws_iam_group.infra_engineer.name
  policy_arn = aws_iam_policy.infra_engineer_access.arn
}

output "eol_dev_iam_groups" {
  value = {
    BillViewer    = aws_iam_group.bill_viewer.name
    Administrator = aws_iam_group.administrator.name
    Developer     = aws_iam_group.developer.name
    InfraEngineer = aws_iam_group.infra_engineer.name
  }
}

output "eol_dev_iam_users" {
  value = sort(tolist(local.all_iam_users))
}
