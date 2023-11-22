#!/bin/bash
# run a series of predefined partition commands

source ./envs.sh
check_var_non_empty IMAGE_FILE PARTITION_COMMANDS

for command in "${PARTITION_COMMANDS[@]}"
do
    parted -s -a optimal -- "${IMAGE_FILE}" $command
done
