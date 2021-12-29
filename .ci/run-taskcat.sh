#!/bin/bash
#run-validation.sh taken from CfCT build 

TASKCAT_INPUT_PATH=$1
TASKCAT_OUTPUT_PATH=$2
CURRENT_PATH=$(pwd)
SUCCESS=0
FAILED=1
EXIT_STATUS=$SUCCESS

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

echo "Printing taskcat input: $TASKCAT_INPUT_PATH"
echo "Printing taskcat output: $TASKCAT_OUTPUT_PATH"

# run taskcat for all template based on the scenario file
echo "Looking for taskcat test scenario from: $TASKCAT_INPUT_PATH/taskcat_scenario.txt"
while IFS="" read -ra TEST || [ -n "$TEST" ]
do
  TEST=($TEST) #put into array
  TEST_NAME=${TEST[0]}
  TEST_PROFILE=${TEST[1]}
  printf '====== Start taskcat test for: %s - cli profile: %s ======\n' "$TEST_NAME" "$TEST_PROFILE"
  printf 'Role to use in aws cli: %s\n' "$TEST_PROFILE"
  taskcat --profile $TEST_PROFILE test run -i $TASKCAT_INPUT_PATH/.taskcat.yml -l -o $TASKCAT_OUTPUT_PATH/$TEST_NAME -t $TEST_NAME
  # catch error and return 
  if [ $? -ne 0 ]
  then
    echo "ERROR: TaskCat test failed - $TEST_NAME"
    set_failed_exit_status
  fi
  printf '====== End taskcat test for: %s ======\n\n' "$TEST_NAME"
done < $TASKCAT_INPUT_PATH/taskcat_scenario.txt

# calling return_code function
exit_shell_script