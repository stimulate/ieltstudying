resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = var.dev_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "eol-dev-cloudfront-cert"
  }
}


locals {
  acm_validation_option = one(
    aws_acm_certificate.cloudfront.domain_validation_options
  )
}


resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.dev.zone_id

  name    = local.acm_validation_option.resource_record_name
  type    = local.acm_validation_option.resource_record_type
  records = [local.acm_validation_option.resource_record_value]

  ttl             = 60
  allow_overwrite = true
}


resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    aws_route53_record.acm_validation.fqdn
  ]
}

bill_viewer_users = [
  "tanaka",
]

developer_users = [
  "sato",
  "yamada",
]

infra_engineer_users = [
  "suzuki",
]

terraform_state_bucket_name = "你现在实际的tfstate-bucket名字"
