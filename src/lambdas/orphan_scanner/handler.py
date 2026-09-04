import json

def handler(event, context):
    print("FinOpsGuard orphan scanner: hello from Lambda")
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "FinOpsGuard Lambda is alive"})
    }
