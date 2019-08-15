from flask_api import FlaskAPI
from flask import request, url_for, jsonify
from flask_api import FlaskAPI, status, exceptions
import requests
import os
from typing import Dict
import json
import re

app = FlaskAPI(__name__)

DATABRICKS_ACCOUNT = os.environ.get("DATABRICKS_ACCOUNT")
DATABRICKS_ACCOUNT = "dbc-e3636760-d7f1.cloud.databricks.com"


def make_url(resource: str, action: str) -> str:
    return f"https://{DATABRICKS_ACCOUNT}/api/2.0/{resource}/{action}"


@app.route("/jobs/run-now", methods=['POST'])
def run_job_now_endpoint():
    if request.method == 'POST':
        pass
    

@app.route("/jobs", methods=['GET', 'POST'])
def jobs_endpoint():
    if request.method == 'GET':
        print("received request")
        url = make_url(resource="jobs", action="list")
        print(url)
        response = requests.get(url)
        response_body: Dict = json.loads(re.sub("(\\r|)\\n$", "", response.text))
        api_response: Dict = {"status_code": response.status_code,
                              "text": response_body}

        return jsonify(api_response)

    elif request.method == "POST":
        pass


if __name__ == "__main__":
    app.run(debug=True)
