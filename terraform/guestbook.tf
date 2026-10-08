# ---------------------------------------------------------------------------
# Guest Book — DynamoDB + Lambda + HTTP API Gateway
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "guestbook" {
  name         = var.guestbook_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = var.guestbook_table_name
  }
}

# --- Lambda execution role ---

data "aws_iam_policy_document" "guestbook_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "guestbook_permissions" {
  statement {
    sid    = "AllowLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/*"]
  }

  statement {
    sid    = "AllowDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query",
    ]
    resources = [aws_dynamodb_table.guestbook.arn]
  }

  statement {
    sid    = "AllowApplyGuardrail"
    effect = "Allow"
    actions = [
      "bedrock:ApplyGuardrail",
    ]
    resources = [aws_bedrock_guardrail.guestbook.guardrail_arn]
  }
}

resource "aws_iam_role" "guestbook" {
  name               = "${var.project_name}-guestbook-lambda"
  assume_role_policy = data.aws_iam_policy_document.guestbook_assume.json
}

resource "aws_iam_role_policy" "guestbook" {
  name   = "${var.project_name}-guestbook-policy"
  role   = aws_iam_role.guestbook.id
  policy = data.aws_iam_policy_document.guestbook_permissions.json
}

# --- Lambda function ---

resource "aws_cloudwatch_log_group" "guestbook" {
  name              = "/aws/lambda/${var.project_name}-guestbook"
  retention_in_days = 14
}

resource "aws_lambda_function" "guestbook" {
  function_name    = "${var.project_name}-guestbook"
  description      = "Guest book API for the demo site (GET/POST entries)"
  filename         = data.archive_file.guestbook_lambda.output_path
  source_code_hash = data.archive_file.guestbook_lambda.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  role             = aws_iam_role.guestbook.arn

  environment {
    variables = {
      GUESTBOOK_TABLE           = aws_dynamodb_table.guestbook.name
      MAX_ENTRIES               = "50"
      AWS_REGION_NAME           = var.aws_region
      GUARDRAIL_ID              = aws_bedrock_guardrail.guestbook.guardrail_id
      GUARDRAIL_VERSION         = aws_bedrock_guardrail_version.guestbook.version
      GUARDRAIL_BLOCKED_MESSAGE = var.guardrail_blocked_message
    }
  }

  depends_on = [
    aws_iam_role_policy.guestbook,
    aws_cloudwatch_log_group.guestbook,
    aws_bedrock_guardrail_version.guestbook,
  ]

  tags = {
    Name = "${var.project_name}-guestbook"
  }
}

# --- HTTP API Gateway ---

resource "aws_apigatewayv2_api" "guestbook" {
  name          = "${var.project_name}-guestbook"
  protocol_type = "HTTP"
  description   = "Guest book API for the demo site"

  cors_configuration {
    allow_origins = ["https://${var.domain_name}"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "guestbook" {
  api_id                 = aws_apigatewayv2_api.guestbook.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.guestbook.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_entries" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "GET /entries"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook.id}"
}

resource "aws_apigatewayv2_route" "post_entries" {
  api_id    = aws_apigatewayv2_api.guestbook.id
  route_key = "POST /entries"
  target    = "integrations/${aws_apigatewayv2_integration.guestbook.id}"
}

resource "aws_apigatewayv2_stage" "guestbook" {
  api_id      = aws_apigatewayv2_api.guestbook.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.guestbook_api.arn
    format = jsonencode({
      requestId  = "$context.requestId"
      httpMethod = "$context.httpMethod"
      routeKey   = "$context.routeKey"
      status     = "$context.status"
    })
  }
}

resource "aws_cloudwatch_log_group" "guestbook_api" {
  name              = "/aws/apigateway/${var.project_name}-guestbook"
  retention_in_days = 14
}

resource "aws_lambda_permission" "guestbook_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guestbook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.guestbook.execution_arn}/*/*"
}
