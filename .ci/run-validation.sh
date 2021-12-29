#!/bin/bash
#run-validation.sh taken from CfCT build 

ARTIFACT_BUCKET=$1
TEMPLATE_PATH=$2
CURRENT_PATH=$(pwd)
SUCCESS=0
FAILED=1
EXIT_STATUS=$SUCCESS
VERSION_1='2020-01-01'
VERSION_2='2021-03-15'

set_failed_exit_status() {
  echo "^^^ Caught an error: Setting exit status flag to $FAILED ^^^"
  EXIT_STATUS=$FAILED
}

exit_shell_script() {
  echo "Exiting script with status: $EXIT_STATUS"
  if [[ $EXIT_STATUS == 0 ]]
    then
      echo "INFO: Validation test(s) completed."
      exit $SUCCESS
    else
      echo "ERROR: One or more validation test(s) failed."
      exit $FAILED
    fi
}

echo "Printing artifact bucket name: $ARTIFACT_BUCKET"
# run aws cloudformation validate-template, cfn_nag_scan and cfn-lint on all **local** templates
cd $TEMPLATE_PATH
TEMPLATES_DIR=$(pwd)
export TEMPLATES_DIR
echo "Changing path to template directory: $TEMPLATES_DIR/"
for template_name in $(find . -type f | grep -E '.template$|.yaml$|.yml$|.json$' | sed 's/^.\///') ; do
    echo "Uploading template: $template_name  to s3"
    aws s3 cp "$TEMPLATES_DIR"/"$template_name" s3://"$ARTIFACT_BUCKET"/validate/templates/"$template_name" --sse aws:kms
    if [ $? -ne 0 ]
    then
      echo "ERROR: Uploading template: $template_name to S3 failed"
      set_failed_exit_status
    fi
done

#V110556787: Intermittent CodeBuild stage failure due to S3 error: Access Denied
sleep_time=30
echo "Sleeping for $sleep_time seconds"
sleep $sleep_time

for template_name in $(find . -type f | grep -E '.template$|.yaml$|.yml$|.json$' | sed 's/^.\///') ; do
    echo "======= $template_name ========"
    echo "Running aws cloudformation validate-template on $template_name"
    aws cloudformation validate-template --template-url https://s3."$AWS_REGION".amazonaws.com/"$ARTIFACT_BUCKET"/validate/templates/"$template_name" --region "$AWS_REGION"
    if [ $? -ne 0 ]
    then
      echo "ERROR: CloudFormation template failed validation - $template_name"
      set_failed_exit_status
    fi
    # delete objects in bucket
    aws s3 rm s3://"$ARTIFACT_BUCKET"/validate/templates/"$template_name"
    echo "Print file encoding: $template_name"
    file -i "$TEMPLATES_DIR"/"$template_name"
    echo "Running cfn_nag_scan on $template_name"
    cfn_nag_scan --input-path "$TEMPLATES_DIR"/"$template_name"
    if [ $? -ne 0 ]
    then
      echo "ERROR: CFN Nag failed validation - $template_name"
      set_failed_exit_status
    fi
    echo "Running cfn-lint on $template_name"
    cfn-lint "$TEMPLATES_DIR"/"$template_name"
    if [ $? -ne 0 ]
    then
      echo "ERROR: CFN Lint failed validation - $file_name"
      set_failed_exit_status
    fi
    
done

cd ..

# calling return_code function
exit_shell_script