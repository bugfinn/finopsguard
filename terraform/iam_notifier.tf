data "aws_iam_policy_document" "notifier_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "slack_notifier" {
  name               = "finopsguard-slack-notifier-role"
  assume_role_policy = data.aws_iam_policy_document.notifier_trust.json

  tags = {
    Project   = "finopsguard"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "slack_notifier_logs" {
  role       = aws_iam_role.slack_notifier.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "notifier_ssm_read" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/finopsguard/slack-webhook-url"]
  }
}

resource "aws_iam_policy" "notifier_ssm_read" {
  name   = "finopsguard-notifier-ssm-read"
  policy = data.aws_iam_policy_document.notifier_ssm_read.json
}

resource "aws_iam_role_policy_attachment" "notifier_ssm_read" {
  role       = aws_iam_role.slack_notifier.name
  policy_arn = aws_iam_policy.notifier_ssm_read.arn
}
