#!/bin/bash

# this script needs to be run on the instance
# simple demonstration of how to run a script to update an internal server

echo running install.sh on internal 1

yum -y update

userdel -r ec2-user

echo finished install.sh on internal 1
