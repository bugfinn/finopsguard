# FinOpsGuard

An event-driven, serverless cloud financial governance engine. FinOpsGuard automates cloud cost monitoring, enforces tagging policies, and safely remediates orphaned resources—built entirely on AWS Always Free tier services ($0/month).

## Architecture: The Four Pillars

* **Pre-Deployment Cost Gating:** Integrates Infracost into the CI/CD pipeline to provide advisory cost estimates on pull requests before infrastructure is provisioned.
* **Tagging Compliance:** Utilizes Open Policy Agent (OPA) to intercept and block the deployment of untagged resources.
* **Automated Two-Phase Remediation:** An EventBridge-triggered Lambda and DynamoDB scanner detects orphaned infrastructure (e.g., unattached EBS volumes), applies a 7-day grace period tag, and permanently deletes the resource only if the tag remains unmodified upon expiration. 
* **Budget Guardrails:** Infrastructure-as-Code implementation of AWS Budgets with tiered thresholds (80% and 100%), wired to an SNS topic for real-time Slack alerting.

## Key Engineering Principles

* **100% Rule-Based:** No black-box machine learning models. Every deletion or alert traces back to an explicit, version-controlled policy.
* **Deterministic Execution:** Hardened edge-case handling (e.g., double-invocation prevention) ensures state remains predictable and consistent.
* **Infrastructure as Code:** The entire architecture, from IAM roles to serverless functions and Slack webhooks, is codified in Terraform.

## Tech Stack

* **Infrastructure:** Terraform, AWS (IAM, SNS, Budgets)
* **Compute & State:** AWS Lambda (Python 3.12), Amazon DynamoDB, Amazon EventBridge Scheduler
* **Policy & CI/CD:** Open Policy Agent (OPA), Infracost, GitHub Actions
* **Alerting:** Slack Webhooks integration
