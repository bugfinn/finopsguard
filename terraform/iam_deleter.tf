data "aws_iam_policy_document" "deleter_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "grace_period_deleter" {
  name               = "finopsguard-grace-period-deleter-role"
  assume_role_policy = data.aws_iam_policy_document.deleter_trust.json

  tags = {
    Project   = "finopsguard"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "deleter_logs" {
  role       = aws_iam_role.grace_period_deleter.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ec2_describe_for_deleter" {
  statement {
    actions   = ["ec2:DescribeVolumes"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_describe_for_deleter" {
  name   = "finopsguard-ec2-describe-for-deleter"
  policy = data.aws_iam_policy_document.ec2_describe_for_deleter.json
}

resource "aws_iam_role_policy_attachment" "deleter_ec2_describe" {
  role       = aws_iam_role.grace_period_deleter.name
  policy_arn = aws_iam_policy.ec2_describe_for_deleter.arn
}

data "aws_iam_policy_document" "ec2_delete" {
  statement {
    actions   = ["ec2:DeleteVolume"]
    resources = ["arn:aws:ec2:us-east-1:${data.aws_caller_identity.current.account_id}:volume/*"]
  }
}

resource "aws_iam_policy" "ec2_delete" {
  name   = "finopsguard-ec2-delete"
  policy = data.aws_iam_policy_document.ec2_delete.json
}

resource "aws_iam_role_policy_attachment" "deleter_ec2_delete" {
  role       = aws_iam_role.grace_period_deleter.name
  policy_arn = aws_iam_policy.ec2_delete.arn
}

data "aws_iam_policy_document" "deleter_dynamodb_write" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.findings.arn]
  }
}

resource "aws_iam_policy" "deleter_dynamodb_write" {
  name   = "finopsguard-deleter-dynamodb-write"
  policy = data.aws_iam_policy_document.deleter_dynamodb_write.json
}

resource "aws_iam_role_policy_attachment" "deleter_dynamodb" {
  role       = aws_iam_role.grace_period_deleter.name
  policy_arn = aws_iam_policy.deleter_dynamodb_write.arn
}

data "aws_iam_policy_document" "deleter_sns_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.findings_alerts.arn]
  }
}

resource "aws_iam_policy" "deleter_sns_publish" {
  name   = "finopsguard-deleter-sns-publish"
  policy = data.aws_iam_policy_document.deleter_sns_publish.json
}

resource "aws_iam_role_policy_attachment" "deleter_sns" {
  role       = aws_iam_role.grace_period_deleter.name
  policy_arn = aws_iam_policy.deleter_sns_publish.arn
}
