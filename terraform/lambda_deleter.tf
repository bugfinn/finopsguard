data "archive_file" "grace_period_deleter_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/grace_period_deleter/handler.py"
  output_path = "${path.module}/build/grace_period_deleter.zip"
}

resource "aws_lambda_function" "grace_period_deleter" {
  function_name    = "finopsguard-grace-period-deleter"
  role             = aws_iam_role.grace_period_deleter.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.grace_period_deleter_zip.output_path
  source_code_hash = data.archive_file.grace_period_deleter_zip.output_base64sha256

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      FINDINGS_TABLE_NAME = aws_dynamodb_table.findings.name
      ALERTS_TOPIC_ARN    = aws_sns_topic.findings_alerts.arn
      DRY_RUN             = "true"
    }
  }

  tags = {
    Project     = "finopsguard"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

output "grace_period_deleter_function_name" {
  value = aws_lambda_function.grace_period_deleter.function_name
}
