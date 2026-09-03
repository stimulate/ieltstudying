resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "eol-dev-static-oac"
  description                       = "OAC for eol-dev static assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Managed cache policy for static assets stored in S3.
data "aws_cloudfront_cache_policy" "s3" {
  name = "Managed-CachingOptimized"
}

# DEV: disable caching for Amplify SSR responses first.
# This avoids accidentally caching login/authentication/dynamic responses.
# Tune this policy later after the application's Cache-Control behavior is confirmed.
data "aws_cloudfront_cache_policy" "amplify_dev" {
  name = "Managed-CachingDisabled"
}

# Forward viewer headers/cookies/query strings to Amplify, except Host.
# CloudFront uses the Amplify origin hostname as the Host header.
data "aws_cloudfront_origin_request_policy" "amplify" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "eol-dev"
  price_class     = var.cloudfront_price_class

  # Custom DEV domain served by this distribution.
  aliases = [var.dev_domain_name]

  # ---------------------------------------------------------------------------
  # Origin 1: Private S3 bucket for static assets
  # ---------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "s3-static"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  # ---------------------------------------------------------------------------
  # Origin 2: Amplify / Next.js SSR
  # Example generated origin: develop.dxxxxxxxxxxxxx.amplifyapp.com
  # ---------------------------------------------------------------------------
  origin {
    domain_name = "${aws_amplify_branch.dev.branch_name}.${aws_amplify_app.web.default_domain}"
    origin_id   = "amplify-ssr"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ---------------------------------------------------------------------------
  # Default behavior -> Amplify SSR
  # ---------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = "amplify-ssr"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    cache_policy_id          = data.aws_cloudfront_cache_policy.amplify_dev.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.amplify.id
    compress                 = true
  }

  # ---------------------------------------------------------------------------
  # Static assets -> S3
  # Example: /assets/*
  # ---------------------------------------------------------------------------
  ordered_cache_behavior {
    path_pattern           = var.s3_path_pattern
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    cache_policy_id = data.aws_cloudfront_cache_policy.s3.id
    compress        = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # CloudFront custom-domain certificate.
  # aws_acm_certificate_validation.cloudfront must use the us-east-1 provider.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Allow only this CloudFront distribution (OAC) to read objects from the
# private static S3 bucket.
data "aws_iam_policy_document" "static_cloudfront" {
  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.static.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.static_cloudfront.json

  # Ensures the public-access-block configuration is already applied before
  # the bucket policy is attached.
  depends_on = [
    aws_s3_bucket_public_access_block.static
  ]
}
