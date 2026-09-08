import json
import os
from datetime import datetime, timezone
import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["FINDINGS_TABLE_NAME"]
TOPIC_ARN = os.environ["ALERTS_TOPIC_ARN"]
DRY_RUN = os.environ.get("DRY_RUN", "true").lower() == "true"

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
ec2 = boto3.client("ec2")
sns = boto3.client("sns")


def find_expired_volumes():
    paginator = ec2.get_paginator("describe_volumes")
    pages = paginator.paginate(
        Filters=[{"Name": "tag-key", "Values": ["finopsguard:pending-delete"]}]
    )

    now = datetime.now(timezone.utc)
    expired = []

    for page in pages:
        for volume in page["Volumes"]:
            tags = {t["Key"]: t["Value"] for t in volume.get("Tags", [])}
            grace_period_end_str = tags.get("finopsguard:pending-delete")
            if not grace_period_end_str:
                continue

            grace_period_end = datetime.fromisoformat(grace_period_end_str)
            if now >= grace_period_end:
                expired.append(volume)

    return expired


def handler(event, context):
    now = datetime.now(timezone.utc).isoformat()
    expired_volumes = find_expired_volumes()
    deleted_count = 0

    for volume in expired_volumes:
        volume_id = volume["VolumeId"]
        state = volume["State"]

        if state != "available":
            print(f"FinOpsGuard: skipping {volume_id}, state is {state} not available")
            continue

        already_gone = False
        delete_failed = False

        if DRY_RUN:
            print(f"FinOpsGuard: DRY RUN, would delete {volume_id}")
        else:
            try:
                ec2.delete_volume(VolumeId=volume_id)
                print(f"FinOpsGuard: deleted {volume_id}")
                deleted_count += 1
            except ClientError as e:
                error_code = e.response["Error"]["Code"]
                if error_code == "InvalidVolume.NotFound":
                    print(
                        f"FinOpsGuard: {volume_id} was already gone, "
                        "likely a duplicate run. Treating as already handled."
                    )
                    already_gone = True
                else:
                    print(f"FinOpsGuard: failed to delete {volume_id}: {error_code}")
                    delete_failed = True

        if delete_failed:
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="FinOpsGuard: deletion failed",
                Message=f"Volume {volume_id}: grace period expired but deletion "
                f"failed ({error_code}). Needs manual review.",
            )
            continue

        if DRY_RUN:
            status = "dry_run_would_delete"
        elif already_gone:
            status = "already_deleted"
        else:
            status = "deleted"

        table.put_item(
            Item={
                "resource_id": volume_id,
                "discovered_at": now,
                "resource_type": "ebs_volume",
                "reason": "grace period expired",
                "status": status,
            }
        )

        subject = "FinOpsGuard: grace period expired" + (" (dry run)" if DRY_RUN else "")
        if DRY_RUN:
            message = f"Volume {volume_id}: grace period expired. Would delete (dry run)."
        elif already_gone:
            message = f"Volume {volume_id}: already deleted, no action needed."
        else:
            message = f"Volume {volume_id}: deleted."

        sns.publish(TopicArn=TOPIC_ARN, Subject=subject, Message=message)

    print(
        f"FinOpsGuard: checked {len(expired_volumes)} expired volume(s), "
        f"deleted {deleted_count} (dry_run={DRY_RUN})"
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "expired_found": len(expired_volumes),
                "deleted": deleted_count,
                "dry_run": DRY_RUN,
            }
        ),
    }
