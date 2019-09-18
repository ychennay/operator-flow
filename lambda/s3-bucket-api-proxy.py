import boto3


def lambda_handler(event, context):
    """
    Make sure to run with an appropriate service role that allows:
    - S3 read access
    - Cloudwatch logging (for logging and execution monitoring)
    """

    # Retrieve the list of existing buckets
    s3 = boto3.client('s3')
    response = s3.list_buckets()

    # Output the bucket names, and convert the native Python Datetime objects
    # into strings (since the Datetime object is not serializable across the wire)
    buckets = []
    for bucket in response['Buckets']:
        buckets.append({"name": bucket["Name"], "createdAt": bucket["CreationDate"].strftime('%m-%d-%Y')})
    return {
        "statusCode": 200,
        "isBase64Encoded": False,
        "headers": {"Access-Control-Allow-Origin": "*"},  # add in response header for CORS enabling
        "body": {"buckets": buckets}
    }
