# Route 53 Alias records for the DEV custom domain.
# The public hosted zone itself is managed in the same DEV root module as:
#   aws_route53_zone.dev

resource "aws_route53_record" "app_a" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = var.dev_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_aaaa" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = var.dev_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
