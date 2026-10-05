# ---------------------------------------------------------------------------
# GitHub Actions OIDC — lets the deploy workflow assume an IAM role without
# storing long-lived AWS access keys as repository secrets.
#
# NOTE on thumbprint: since 2023-07 AWS validates GitHub's OIDC endpoint
# against its own trusted CA library, so the thumbprint is no longer used for
# validation. The field is still required, so the well-known value is supplied.
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# Trust policy: only workflows from the specified repo may assume the role.
data "aws_iam_policy_document" "github_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # This repo has GitHub's immutable identifiers enabled, so the OIDC subject
    # includes the numeric org/repo IDs:
    #   repo:<org>@<org_id>/<repo>@<repo_id>:environment:<env>
    # The role is scoped to deployments from the "demo" environment only.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}@${var.github_org_id}/${var.github_repo}@${var.github_repo_id}:environment:${var.github_environment}",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-gh"
  description        = "Assumed by GitHub Actions to deploy the demo site"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json

  tags = {
    Name = "${var.project_name}-GitHubActionsRole"
  }
}

# Deploy permissions: sync files to S3 and invalidate the CloudFront cache.
data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid    = "AllowS3Sync"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }

  statement {
    sid    = "AllowCloudFrontInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "${var.project_name}-deploy-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_deploy.json
}
