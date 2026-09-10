# FinOpsGuard

A serverless cloud governance engine that watches an AWS account for wasted spend, tags what it finds instead of deleting it outright, and only follows through after a real waiting period passes untouched. Built as a learning project to actually understand how real FinOps tooling works, not to copy a tutorial. It also runs at genuinely $0 a month.

## What it actually does

Four pieces, each doing a different job:

**Cost visibility.** Every pull request touching Terraform gets an automatic price estimate from Infracost, posted as a comment. It's informational only, on purpose — nothing here blocks a merge. The goal is never shipping a cost surprise, not handing a machine veto power over your infrastructure.

**Tagging enforcement.** A set of Rego policies, run through OPA and Conftest, checks that anything taggable carries the required tags. Unlike the cost check, this one is a real, required gate on `main` — a pull request can't merge if it fails.

**Orphan detection and two-phase remediation.** A Lambda scans the account every six hours for resources that look abandoned, like an EBS volume nothing is attached to. When it finds one, it doesn't delete it. It tags the resource with a note that says it's gone in 7 days unless someone objects, writes a record to DynamoDB, and sends a Slack alert. A second Lambda checks once a day whether that window has actually run out and the tag is still there. Only then does it delete, and it tells you when it does.

**Budget guardrail.** An AWS Budget set to $1 a month, watching total spend independently of everything above, with alerts at 80% and 100% routed to the same Slack channel.

## Why no machine learning

Deliberate choice, not a limitation. Every action this system takes needs to trace back to a specific rule someone can point to and explain. When something is about to disappear permanently, "because this exact condition was true" is a better answer than "because a model's confidence crossed a threshold." If this project ever adds real ML, it'll be for softer things like anomaly detection or forecasting feeding into an alert, never a delete decision made on its own.

## How it's built

- **Infrastructure:** Terraform, entirely on AWS's Always Free tier (Lambda, DynamoDB, SNS, EventBridge Scheduler, Budgets)
- **Compute:** Python 3.12 Lambdas
- **Policy:** Open Policy Agent / Conftest, written in Rego
- **Cost estimation:** Infracost CLI, run in GitHub Actions
- **Alerting:** SNS to a Lambda that posts to Slack, with the webhook URL stored in SSM Parameter Store as a SecureString, never in code

## A note on "$0/month"

True for this specific account, running this specific amount of infrastructure. Deploying this yourself means checking AWS's current Free Tier terms for your own account, and adjusting a couple of things hardcoded to this setup first, like the AWS CLI profile name and region.

## Status

All four pillars built and tested against real AWS resources, including a real detection-to-deletion cycle. Full writeup in progress.
