#!/bin/bash

echo "Generating Databricks API netrc configuration"
cat <<EOT >>$HOME/.netrc
machine $DATABRICKS_ACCOUNT
login token
password $DATABRICKS_TOKEN
EOT

echo ".netrc file generated and stored in ${HOME}/.netrc"
