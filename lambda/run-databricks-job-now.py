import boto3
from botocore.vendored import requests

ssm = boto3.client('ssm')
DB_TOKEN = ssm.get_parameter(Name="databricks_token", WithDecryption=True)["Parameter"]["Value"]
DATABRICKS_ACCOUNT = ssm.get_parameter(Name="databricks_deployment_hostname")["Parameter"]["Value"]


def make_url(resource: str = "jobs", action: str = "run-now") -> str:
    return f"https://{DATABRICKS_ACCOUNT}/api/2.0/{resource}/{action}"


def lambda_handler(event, context):
    headers = {
        "Authorization": f"Bearer {DB_TOKEN}"
    }
    assert event["httpMethod"] in ["POST", "GET"]

    full_url = make_url() if event["httpMethod"] == "POST" else make_url(action="runs/list")
    if event["httpMethod"] == "POST":
        response = requests.post(full_url, headers=headers, data=event["body"])
    else:
        response = requests.get(full_url, headers=headers)
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": response.text
    }
