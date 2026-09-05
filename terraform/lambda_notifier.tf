data "archive_file" "slack_notifier_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/slack_notifier/handler.py"
  output_path = "${path.module}/build/slack_notifier.zip"
}

resource "aws_lambda_function" "slack_notifier" {
  function_name    = "finopsguard-slack-notifier"
  role             = aws_iam_role.slack_notifier.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.slack_notifier_zip.output_path
  source_code_hash = data.archive_file.slack_notifier_zip.output_base64sha256

  timeout     = 15
  memory_size = 128

  tags = {
    Project     = "finopsguard"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

resource "aws_sns_topic_subscription" "notifier_subscription" {
  topic_arn = aws_sns_topic.findings_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.findings_alerts.arn
}
