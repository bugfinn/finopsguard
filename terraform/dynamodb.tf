resource "aws_dynamodb_table" "findings" {
  name         = "finopsguard-findings"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "resource_id"
  range_key = "discovered_at"

  attribute {
    name = "resource_id"
    type = "S"
  }

  attribute {
    name = "discovered_at"
    type = "S"
  }

  tags = {
    Project     = "finopsguard"
    Environment = "learning"
    ManagedBy   = "terraform"
  }
}

output "findings_table_name" {
  value = aws_dynamodb_table.findings.name
}
