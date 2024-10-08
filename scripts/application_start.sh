#!/bin/bash

cd /aws-codepipeline

# Retrieve environment variables
export DAGSTER_POSTGRES_HOSTNAME=$(aws ssm get-parameter --name "DAGSTER_POSTGRES_HOSTNAME" --query "Parameter.Value" --output text)
export DAGSTER_POSTGRES_USERNAME=$(aws ssm get-parameter --name "DAGSTER_POSTGRES_USERNAME" --query "Parameter.Value" --output text)
export DAGSTER_POSTGRES_PASSWORD=$(aws ssm get-parameter --name "DAGSTER_POSTGRES_PASSWORD" --with-decryption --query "Parameter.Value" --output text)
export DAGSTER_POSTGRES_DB_NAME=$(aws ssm get-parameter --name "DAGSTER_POSTGRES_DB_NAME" --query "Parameter.Value" --output text)

# Build and Run
sudo -E docker compose -f ci/docker-compose.yaml up -d --build