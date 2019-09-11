# Lambda Functions

The files stored here are version-controlled AWS Lambda functions that server as lambda proxies for different REST resources on the
operatorflow API Gateway. The following functions are stored:

* `s3-bucket-api-proxy`: Lambda function that will use the `boto3` S3 API to list buckets and creation times. 

## FAQ

1. Why did you decide to use an AWS Lambda function to query your S3 backend? There is an actual [AWS S3 Service Endpoint](https://docs.aws.amazon.com/apigateway/latest/developerguide/integrating-api-with-aws-services-s3.html#api-root-get-as-s3-get-service)
available to call directly from API Gateway.
There is indeed an actual AWS endpoint, but this requires many custom configurations of the integration response header mappings, since the default
response is in XML, and the actual frontend client app (written in Javascript) expects JSON. Thus, in order to avoid the client having to do manual conversion
of XML to JSON, I opted to simply write my own implementation in `boto3`, which is easily mappable to JSON.
