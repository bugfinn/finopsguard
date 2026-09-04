data "archive_file" "orphan_scanner_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/orphan_scanner/handler.py"
  output_path = "${path.module}/build/orphan_scanner.zip"
}

resource "aws_lambda_function" "orphan_scanner" {
  function_name    = "finopsguard-orphan-scanner"
  role             = aws_iam_role.orphan_scanner.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.orphan_scanner_zip.output_path
  source_code_hash = data.archive_file.orphan_scanner_zip.output_base64sha256

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      FINDINGS_TABLE_NAME = aws_dynamodb_table.findings.name
    }
  }

  tags = {
    Project     = "finopsguard"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

output "orphan_scanner_function_name" {
  value = aws_lambda_function.orphan_scanner.function_name
}
