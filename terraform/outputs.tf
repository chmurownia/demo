output "site_url" {
  description = "Public URL of the demo site"
  value       = "https://${var.domain_name}"
}

output "site_bucket_name" {
  description = "Name of the S3 bucket holding the site files"
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidation)"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "guestbook_api_endpoint" {
  description = "Base URL of the guest book API. Append /entries for the frontend."
  value       = "${aws_apigatewayv2_stage.guestbook.invoke_url}/entries"
}

output "guestbook_table_name" {
  description = "DynamoDB table name for guest book entries"
  value       = aws_dynamodb_table.guestbook.name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions. Set as GHA variable AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
