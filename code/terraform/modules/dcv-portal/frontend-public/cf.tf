# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access_control" {
  name                              = "${var.env.prefix}-frontend-s3-oac"
  description                       = "CloudFront S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# data "aws_cloudfront_cache_policy" "cloudfront_cache_policy_caching_optimized" {
#   name = "Managed-CachingOptimized"
# }

data "aws_cloudfront_origin_request_policy" "cloudfront_origin_request_policy_cors_s3origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  enabled             = true
  comment             = "[${var.env.prefix}] Cloudfront distrinbution"
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  web_acl_id          = (var.module_network.config.ip_allow_list_enabled == true ? aws_wafv2_web_acl.wafv2_web_acl[0].arn : "") 

  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    include_cookies = false
  }

  origin {
    domain_name = var.config.web_content_bucket_domain_name
    origin_id   = local.origin_id_s3
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access_control.id
  }

  origin {
    domain_name = "${var.module_dcv.api_gateway_rest_api.id}.execute-api.${var.env.region}.amazonaws.com"
    origin_id   = local.origin_id_api
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods          = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = local.origin_id_s3
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized data.aws_cloudfront_cache_policy.cloudfront_cache_policy_caching_optimized.id
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin    data.aws_cloudfront_origin_request_policy.cloudfront_origin_request_policy_cors_s3origin
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id_api
    # cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    viewer_protocol_policy = "https-only"
    compress               = true

    forwarded_values {
      query_string = true
      headers = [
        "Authorization",
        "Origin",
        "Accept",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "Referer",
        "Accept-Encoding"
      ]
      cookies {
        forward = "none"
      }
    }
    
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" // specify some geo restriction if needed
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true // use ACM if needed
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/"
    error_caching_min_ttl = 10
  }
}

data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${var.config.web_content_bucket_id}/*" ]
    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [aws_cloudfront_distribution.cloudfront_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = var.config.web_content_bucket_id
  policy = data.aws_iam_policy_document.iam_policy_document.json
}

