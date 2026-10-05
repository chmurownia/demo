variable "aws_region" {
  description = "AWS region for regional resources (S3, DynamoDB, Lambda, API Gateway)"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging resources"
  type        = string
  default     = "chmurownia-demo"
}

variable "account_id" {
  description = "AWS account ID of the demo account"
  type        = string
  default     = "727329303802"
}

variable "domain_name" {
  description = "Fully qualified domain name for the demo site"
  type        = string
  default     = "demo.chmurownia.org"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for demo.chmurownia.org"
  type        = string
  default     = "Z07977711BCKZWIPUNYAP"
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository (as shown in the OIDC subject)"
  type        = string
  default     = "chmurownia"
}

variable "github_org_id" {
  description = "Immutable GitHub organization ID (shown in the OIDC subject as org@ID)"
  type        = string
  default     = "331737546"
}

variable "github_repo" {
  description = "GitHub repository name allowed to assume the deploy role"
  type        = string
  default     = "demo"
}

variable "github_repo_id" {
  description = "Immutable GitHub repository ID (shown in the OIDC subject as repo@ID)"
  type        = string
  default     = "1391044409"
}

variable "github_environment" {
  description = "GitHub Actions environment name allowed to assume the deploy role"
  type        = string
  default     = "demo"
}

variable "site_bucket_name" {
  description = "S3 bucket name for the static site (must be globally unique)"
  type        = string
  default     = "chmurownia-demo-site"
}

variable "guestbook_table_name" {
  description = "DynamoDB table name for guest book entries"
  type        = string
  default     = "chmurownia-demo-guestbook"
}

variable "lambda_source_dir" {
  description = "Path to the guest book Lambda source directory (relative to module)"
  type        = string
  default     = "../lambda/guestbook"
}
