output "cloudfront_waf_arn" {
  value = aws_wafv2_web_acl.block_web_acl.arn
}