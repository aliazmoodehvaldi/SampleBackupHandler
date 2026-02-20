#!/bin/bash

base_path=$(echo $1 | sed 's/.*=//')
. "$base_path/utils/init.sh" $base_path

olderThan=$(date -d "$STORAGE_PERIOD days ago" +%s)

run_for_profile () {
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

    aws s3 ls "s3://$bucket" \
        --profile "$profile" \
        --endpoint-url "$endpoint" | while read -r line; do

        createDate=$(echo "$line" | awk '{print $1}')
        fileName=$(echo "$line" | awk '{print $4}')
        fileDate=$(date -d "$createDate" +%s)

        if [[ $fileDate -lt $olderThan && -n "$fileName" ]]; then
            aws s3 rm "s3://$bucket/$fileName" \
                --profile "$profile" \
                --endpoint-url "$endpoint"
        fi
    done
}

if [[ "$MULTI_ACCOUNT" == "true" ]]; then
    for profile in $(aws configure list-profiles); do
        echo "Processing profile: $profile"
        run_for_profile "$profile"
    done
else
    run_for_profile "default"
fi