#!/bin/bash
# use to run script on multiple devices 
# usually after running upgrade.sls on multiple devices

# List of router names. Example:
# NAMES=(router1 router2)
NAMES=()

for name in ${NAMES[*]}; do
    echo "-----------------------------------"
    echo $name
    echo "-----------------------------------"
   # ./install_requirements.sh $name
   # ./fix_oserror.sh $name
done

