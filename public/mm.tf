provider "aws" {
  profile = "eol-dev"
  region  = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = "eol"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias   = "us_east_1"
  profile = "eol-dev"
  region  = "us-east-1"

  default_tags {
    tags = {
      Project     = "eol"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

dev_domain_name = "你的DEV域名"

budget_email       = "你的通知邮箱"
monthly_budget_usd = 100

repository_url = "你的GitHub仓库URL"
amplify_branch = "develop"
