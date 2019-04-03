#!/bin/bash

# this script demos nested expects
# it simulates a bash script which is
# requesting input with 'read'

echo "connecting to server..."

read -s -p "MFA code for required:" mfacode
echo
echo mfacode=$mfacode

echo "done connecting"
