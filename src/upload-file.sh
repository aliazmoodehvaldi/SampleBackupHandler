#!/bin/bash

base_path=$(echo $1 | sed 's/.*=//')
. "$base_path/utils/init.sh" $base_path

filename=$(basename "$2")

file_dir=$2

upload_with_profile () {
    local profile=$1
    local endpoint=""
    local bucket=""

    if [[ "$MULTI_ACCOUNT" == "true" ]]; then
        local upper_profile=$(echo "$profile" | tr '[:lower:]' '[:upper:]')

        local endpoint_var="ENDPOINT_URL_${upper_profile}"
        endpoint="${!endpoint_var}"
        if [[ -z "$endpoint" ]]; then
            echo "No endpoint defined for profile: $profile"
            return 1
        fi

        local bucket_var="S3_BUCKET_${upper_profile}"
        bucket="${!bucket_var}"
        if [[ -z "$bucket" ]]; then
            echo "No S3 bucket defined for profile: $profile"
            return 1
        fi
    else
        endpoint="$ENDPOINT_URL"
        bucket="$S3_BUCKET"

        if [[ -z "$endpoint" ]]; then
            echo "No endpoint defined for single account."
            return 1
        fi
        if [[ -z "$bucket" ]]; then
            echo "No S3 bucket defined for single account."
            return 1
        fi
    fi

    aws s3 cp "$file_dir" "s3://$bucket/$filename" \
        --profile "$profile" \
        --endpoint-url "$endpoint"
}

if [[ "$MULTI_ACCOUNT" == "true" ]]; then
    for profile in $(aws configure list-profiles); do
        echo "Uploading with profile: $profile"
        upload_with_profile "$profile"
    done
else
    upload_with_profile "default"
fi