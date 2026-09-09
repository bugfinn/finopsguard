# TEMPORARY — for testing the OPA tagging policy check only.
# This branch will be closed without merging; this file never reaches main.

resource "aws_dynamodb_table" "policy_test" {
  name         = "finopsguard-policy-test"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "finopsguard"
  }
}
