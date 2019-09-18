import boto3


def lambda_handler(event, context):
    # Create an SNS client
    sns = boto3.client('sns')
    print(event)
    # Publish a simple message to the specified SNS topic
    response = sns.publish(
        TopicArn='arn:aws:sns:us-east-1:892003309670:user-signed-up',
        Message='User Signed up',
    )

    # Print out the response
    return event