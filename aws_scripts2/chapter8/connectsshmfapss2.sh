#!/bin/bash

# open an ssh session to a server
# which has keys disabled and MFA enabled
# then automate the 'sudo su' password entry
# as created by make.sh in this directory (chapter8)

# ALSO require MFA to activate AWS CLI

# for the sign in and sign out scripts below,
# you could move them to the same directory and
# leave out '../chapter4/output/'

# sign out
./../chapter4/output/signout.sh

# sign in as connect 
# you'll need to enter an MFA code
./../chapter4/output/signin.sh connect

# now connect
./connectsshmfapss.sh

# sign out of aws cli
./../chapter4/output/signout.sh
