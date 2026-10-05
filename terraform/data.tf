data "aws_caller_identity" "current" {}

# Package the guest book Lambda source into a deployment zip
data "archive_file" "guestbook_lambda" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/guestbook_lambda.zip"
}
