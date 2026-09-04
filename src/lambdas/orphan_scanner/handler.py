import json
import os
from datetime import datetime, timezone
import boto3

TABLE_NAME = os.environ["FINDINGS_TABLE_NAME"]

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    now = datetime.now(timezone.utc).isoformat()

    item = {
        "resource_id": "test-connection-check",
        "discovered_at": now,
        "reason": "manual test write from Step 5",
        "status": "test",
    }

    table.put_item(Item=item)

    print(f"FinOpsGuard: wrote test item to {TABLE_NAME} at {now}")

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "wrote test item",
                "resource_id": item["resource_id"],
                "discovered_at": now,
            }
        ),
    }
