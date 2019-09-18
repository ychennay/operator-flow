## Databricks-Specific Infrastructure

This module contains an initial implementation of the Flask API proxy server
that was intended to be used to counteract CORS limitations of the Databricks API. However,
the code here was ultimately not put into production, as it was ultimately superseded and replaced with
a serverless API Gateway implementation (found in the `api_gateway/` module).