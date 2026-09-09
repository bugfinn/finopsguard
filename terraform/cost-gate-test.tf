# TEMPORARY — for testing the Infracost PR cost-gate only.
# This branch will be closed without merging; this file never reaches main.

resource "aws_ebs_volume" "cost_gate_test" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"

  tags = {
    Project = "finopsguard-cost-gate-test"
  }
}
