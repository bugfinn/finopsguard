data "aws_iam_policy_document" "findings_alerts_topic_policy" {
  statement {
    sid    = "AllowBudgetsToPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.findings_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "findings_alerts_policy" {
  arn    = aws_sns_topic.findings_alerts.arn
  policy = data.aws_iam_policy_document.findings_alerts_topic_policy.json
}

resource "aws_budgets_budget" "monthly_guardrail" {
  name         = "finopsguard-monthly-guardrail"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.findings_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.findings_alerts.arn]
  }

  depends_on = [aws_sns_topic_policy.findings_alerts_policy]
}
