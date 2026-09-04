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
