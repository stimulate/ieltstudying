terraform {
  backend "s3" {
    bucket       = "你的实际tfstate-bucket-name"
    key          = "eol/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    profile      = "eol-dev"
    use_lockfile = true
  }
}
