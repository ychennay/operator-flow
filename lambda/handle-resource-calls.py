import boto3
from botocore.vendored import requests

ssm = boto3.client('ssm')
DB_TOKEN = ssm.get_parameter(Name="databricks_token", WithDecryption=True)["Parameter"]["Value"]
DATABRICKS_ACCOUNT = ssm.get_parameter(Name="databricks_deployment_hostname")["Parameter"]["Value"]


def make_url(resource: str, action: str) -> str:
    return f"https://{DATABRICKS_ACCOUNT}/api/2.0/{resource}/{action}"


resource_dictionary = {
    "cluster": "clusters",
    "job": "jobs",
    "workspace": "workspace"
}

method_dictionary = {
    "GET": "list",
    "POST": "create"
}


def lambda_handler(event, context):
    headers = {
        "Authorization": f"Bearer {DB_TOKEN}"
    }

    action = method_dictionary[event["httpMethod"]]
    resource = event["path"].replace("/", "")
    final_resource = resource_dictionary[resource]

    full_url = make_url(final_resource, action)
    if event["httpMethod"] == "GET":
        response = requests.get(full_url, headers=headers)
    elif event["httpMethod"] == "POST":
        response = requests.post(full_url, headers=headers, data=event["body"])
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": response.text
    }
