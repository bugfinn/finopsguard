data "aws_caller_identity" "current" {}

output "confirmed_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "confirmed_identity_arn" {
  value = data.aws_caller_identity.current.arn
}
