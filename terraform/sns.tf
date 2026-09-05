resource "aws_sns_topic" "findings_alerts" {
  name = "finopsguard-findings-alerts"

  tags = {
    Project   = "finopsguard"
    ManagedBy = "terraform"
  }
}
