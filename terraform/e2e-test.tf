# TEMPORARY — final end-to-end demonstration of the full CI pipeline.
# This branch will be closed without merging; this file never reaches main.

resource "aws_ebs_volume" "e2e_demo" {
  availability_zone = "us-east-1a"
  size              = 50
  type              = "gp3"

  tags = {
    Project = "finopsguard"
  }
}
