#!/bin/bash

# interactive script to show how mfa sign in and sign out can be used in a script

# sign out
./output/signout.sh

# try a command (it won't work)
aws ec2 describe-instances

# sign in (you'll need to enter an mfa code)
./output/signin.sh admin

# now you can do whatever - run a script or some commands
# we'll use a test command
echo RUNNING PRIVILEGED COMMANDS
aws ec2 describe-instances
echo FINISHED PRIVILEGED COMMANDS

# when you're finished, sign out again
./output/signout.sh

# try a command (it won't work)
aws ec2 describe-key-pairs

# now sign in as connect (you'll need to enter an mfa code)
./output/signin.sh connect

# now you can run:
# describe-instances
# describe-security-groups
# authorize-security-group-ingress
# revoke-security-group-ingress

# we'll use a test command
echo RUNNING PRIVILEGED COMMANDS
# this will work
aws ec2 describe-instances
# this won't
aws ec2 describe-key-pairs
echo FINISHED PRIVILEGED COMMANDS

# when you're finished, sign out again
./output/signout.sh

# try a command (it won't work)
aws ec2 describe-instances
