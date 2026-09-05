data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "orphan_scanner" {
  name               = "finopsguard-orphan-scanner-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = {
    Project   = "finopsguard"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "orphan_scanner_logs" {
  role       = aws_iam_role.orphan_scanner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_write" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.findings.arn]
  }
}

resource "aws_iam_policy" "dynamodb_write" {
  name   = "finopsguard-dynamodb-write"
  policy = data.aws_iam_policy_document.dynamodb_write.json
}

resource "aws_iam_role_policy_attachment" "orphan_scanner_dynamodb" {
  role       = aws_iam_role.orphan_scanner.name
  policy_arn = aws_iam_policy.dynamodb_write.arn
}

data "aws_iam_policy_document" "ec2_read" {
  statement {
    actions   = ["ec2:DescribeVolumes"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_read" {
  name   = "finopsguard-ec2-read"
  policy = data.aws_iam_policy_document.ec2_read.json
}

resource "aws_iam_role_policy_attachment" "orphan_scanner_ec2" {
  role       = aws_iam_role.orphan_scanner.name
  policy_arn = aws_iam_policy.ec2_read.arn
}

data "aws_iam_policy_document" "sns_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.findings_alerts.arn]
  }
}

resource "aws_iam_policy" "sns_publish" {
  name   = "finopsguard-sns-publish"
  policy = data.aws_iam_policy_document.sns_publish.json
}

resource "aws_iam_role_policy_attachment" "orphan_scanner_sns" {
  role       = aws_iam_role.orphan_scanner.name
  policy_arn = aws_iam_policy.sns_publish.arn
}
