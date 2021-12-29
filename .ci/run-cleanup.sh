#!/bin/bash
TASKCAT_PROFILE=$1
echo "Deleting all test S3 bucket created by stack / stackset"
set +e;
aws s3 rb s3://$FLOWLOG_BUCKET_NAME --force --profile $LOGARCHIVE_PROFILE_NAME
set -e;
echo "Cleaning up TaskCat Project"
taskcat test clean ALL -a $TASKCAT_PROFILE