import json
import urllib.request
import boto3

ssm = boto3.client("ssm")

_webhook_url_cache = None


def get_webhook_url():
    global _webhook_url_cache
    if _webhook_url_cache is None:
        response = ssm.get_parameter(
            Name="/finopsguard/slack-webhook-url", WithDecryption=True
        )
        _webhook_url_cache = response["Parameter"]["Value"]
    return _webhook_url_cache


def handler(event, context):
    webhook_url = get_webhook_url()

    for record in event["Records"]:
        sns_message = record["Sns"]["Message"]

        slack_payload = {
            "text": f":triangular_flag_on_post: FinOpsGuard finding\n{sns_message}"
        }

        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(slack_payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req) as response:
            status = response.status
            body = response.read().decode("utf-8")
            print(f"FinOpsGuard: Slack responded {status} - {body}")
    return {"statusCode": 200}
