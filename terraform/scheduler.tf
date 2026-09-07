data "aws_iam_policy_document" "scheduler_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler_invoke" {
  name               = "finopsguard-scheduler-invoke-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler_trust.json

  tags = {
    Project   = "finopsguard"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "scheduler_invoke_lambda" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.orphan_scanner.arn]
  }
}

resource "aws_iam_policy" "scheduler_invoke_lambda" {
  name   = "finopsguard-scheduler-invoke-lambda"
  policy = data.aws_iam_policy_document.scheduler_invoke_lambda.json
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_lambda" {
  role       = aws_iam_role.scheduler_invoke.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}

resource "aws_scheduler_schedule" "orphan_scanner_schedule" {
  name = "finopsguard-orphan-scanner-schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(6 hours)"

  target {
    arn      = aws_lambda_function.orphan_scanner.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
  }
}

data "aws_iam_policy_document" "scheduler_invoke_deleter" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.grace_period_deleter.arn]
  }
}

resource "aws_iam_policy" "scheduler_invoke_deleter" {
  name   = "finopsguard-scheduler-invoke-deleter"
  policy = data.aws_iam_policy_document.scheduler_invoke_deleter.json
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_deleter" {
  role       = aws_iam_role.scheduler_invoke.name
  policy_arn = aws_iam_policy.scheduler_invoke_deleter.arn
}

resource "aws_scheduler_schedule" "grace_period_deleter_schedule" {
  name = "finopsguard-grace-period-deleter-schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 day)"

  target {
    arn      = aws_lambda_function.grace_period_deleter.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
  }
}
