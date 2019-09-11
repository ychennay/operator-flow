import json
from botocore.vendored import requests 
import os
import boto3

DATABRICKS_ACCOUNT = "dbc-e3636760-d7f1.cloud.databricks.com"

def make_url(account: str, resource: str, action: str) -> str:
    return f"https://{account}/api/2.0/{resource}/{action}"


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
    
    # Create Parameter Store client to access sensitive parameters (databricks token), give it the ability to decrypt
    ssm = boto3.client('ssm')
    DB_TOKEN = ssm.get_parameter(Name="databricks_token", WithDecryption=True)["Parameter"]["Value"]
    DATABRICKS_ACCOUNT = ssm.get_parameter(Name="databricks_deployment_hostname")["Parameter"]["Value"]
    
    headers = {
        "Authorization": f"Bearer {DB_TOKEN}" # attach the bearer token
    }
    payload = {"path": "/Users/ychen244@syr.edu/"}
    action = method_dictionary[event["httpMethod"]]
    resource = event["path"].replace("/", "")
    final_resource = resource_dictionary[resource]
    
    full_url = make_url(DATABRICKS_ACCOUNT, final_resource, action)
    response = requests.get(full_url, headers=headers, params=payload)
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {
            "Access-Control-Allow-Origin": "*" # enable CORS
        },
        "body": response.text
        }
