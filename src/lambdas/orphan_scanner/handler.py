import json
import os
from datetime import datetime, timedelta, timezone
import boto3
TABLE_NAME = os.environ["FINDINGS_TABLE_NAME"]

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
ec2 = boto3.client("ec2")
sns = boto3.client("sns")
TOPIC_ARN = os.environ["ALERTS_TOPIC_ARN"]

def find_unattached_volumes():
    paginator = ec2.get_paginator("describe_volumes")
    pages = paginator.paginate(
        Filters=[{"Name": "status", "Values": ["available"]}]
    )

    volumes = []
    for page in pages:
        volumes.extend(page["Volumes"])

    return volumes


def handler(event, context):
    now = datetime.now(timezone.utc).isoformat()
    volumes = find_unattached_volumes()

    for volume in volumes:
        volume_id = volume["VolumeId"]
        size_gb = volume["Size"]
        estimated_monthly_cost = round(size_gb * 0.08, 2)

        item = {
            "resource_id": volume_id,
            "discovered_at": now,
            "resource_type": "ebs_volume",
            "reason": f"unattached, {size_gb}GB",
            "estimated_monthly_cost": str(estimated_monthly_cost),
            "status": "flagged",
        }
        table.put_item(Item=item)
        grace_period_end = (
            datetime.now(timezone.utc) + timedelta(days=7)
        ).isoformat()

        ec2.create_tags(
            Resources=[volume_id],
            Tags=[
                {"Key": "finopsguard:pending-delete", "Value": grace_period_end},
                {"Key": "finopsguard:flagged-by", "Value": "finopsguard-orphan-scanner"},
            ],
        )
        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=f"Unattached EBS volume {volume_id} ({size_gb}GB, ~${estimated_monthly_cost}/month)",
            Subject="FinOpsGuard: unattached volume detected",
        )
    print(f"FinOpsGuard: scan complete, found {len(volumes)} unattached volume(s)")

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"message": "scan complete", "unattached_volumes_found": len(volumes)}
        ),
    }
