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
