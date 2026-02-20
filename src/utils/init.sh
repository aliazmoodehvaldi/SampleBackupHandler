#!/bin/bash

. "$1/utils/utils.sh"

# Check exist aws tools
if ! has_exist_command "aws"; then
    echo "${red}Error: aws does not found"
    exit 1
fi

# Check if .env file exists
if [ -f "$1/.env" ]; then
    # Load variables from .env file
    . "$1/.env"
else
    echo "${red}Error: .env file not found."
    exit 1
fi

# Define the list of environment variable names
env_variables=(
    "WORDPRESS_DOCKER_NAME"
    "ARCHIVE_MONGODB_PATH"
    "ARCHIVE_MYSQL_PATH"
    "MYSQL_DOCKER_NAME"
    "MONGODB_PASSWORD"
    "SECOND_CONTAINER"
    "MONGODB_USERNAME"
    "MYSQL_DATABASE"
    "MYSQL_PASSWORD"
    "STORAGE_PERIOD"
    "MULTI_ACCOUNT"
    "MONGODB_PORT"
    "ENDPOINT_URL"
    "PROJECT_NAME"
    "SCRIPT_PATH"
    "TARGET_PATH"
    "MYSQL_USER"
    "S3_BUCKET"
)

# Check if all required env variables are set
for var_name in "${env_variables[@]}"; do
    if [ -z "${!var_name}" ]; then
        echo "${yellow}Warning: $var_name is not set"
    fi
done

# --- New check for MULTI_ACCOUNT ---
if [[ "$MULTI_ACCOUNT" == "true" ]]; then
    # Get all AWS CLI profiles
    profiles=$(aws configure list-profiles)
    
    missing=0
    
    for profile in $profiles; do
        upper_profile=$(echo "$profile" | tr '[:lower:]' '[:upper:]')
        
        # Check endpoint
        endpoint_var="ENDPOINT_URL_${upper_profile}"
        if [ -z "${!endpoint_var}" ]; then
            echo "${red}Error: Endpoint for profile '$profile' not set. Expected env variable: $endpoint_var"
            missing=1
        fi

        # Check bucket
        bucket_var="S3_BUCKET_${upper_profile}"
        if [ -z "${!bucket_var}" ]; then
            echo "${red}Error: S3 bucket for profile '$profile' not set. Expected env variable: $bucket_var"
            missing=1
        fi
    done

    if [[ $missing -eq 1 ]]; then
        echo "${red}Please set all required ENDPOINT_URL_<PROFILE> and S3_BUCKET_<PROFILE> variables in your .env file."
        exit 1
    fi
else
    if [ -z "$S3_BUCKET" ]; then
        echo "${red}Error: S3_BUCKET is not set for single account."
        exit 1
    fi
    if [ -z "$ENDPOINT_URL" ]; then
        echo "${red}Error: ENDPOINT_URL is not set for single account."
        exit 1
    fi
fi