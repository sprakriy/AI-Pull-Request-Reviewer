# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "ai-pr-reviewer-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  lifecycle { prevent_destroy = true }
}

# IAM Policy to allow invoking Amazon Bedrock
resource "aws_iam_policy" "bedrock_policy" {
  name = "ai-pr-reviewer-bedrock-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel"
        ]
        Effect   = "Allow"
        Resource = "*" # Can be restricted to specific foundation models
      }
    ]
  })
  lifecycle { prevent_destroy = true }
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

# Archive Lambda Code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/modules/pr_reviewer/src/lambda_function.py"
  output_path = "${path.module}/build/lambda_function.zip"
}

# AWS Lambda Function
resource "aws_lambda_function" "reviewer_function" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ai-pr-reviewer-dev"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      BEDROCK_MODEL_ID = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    }
  }
}

# Lambda Function URL for direct HTTP invocation
resource "aws_lambda_function_url" "reviewer_url" {
  function_name      = aws_lambda_function.reviewer_function.function_name
  authorization_type = "NONE" # You can secure this using AWS IAM or IP allowlisting in production
}

output "function_url" {
  value = aws_lambda_function_url.reviewer_url.function_url
}