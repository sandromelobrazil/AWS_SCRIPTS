#!/bin/bash

# this script closes any cidr rules for the specified port for all security group
# call it with 1 argument
# ./closeportsallsgs <port>
# eg ./closeportsallsgs 22 would close port 22 cidr rules in all security groups

# this script calls the closeports.sh script

# read arguments
port=$1

# get all security groups with specified port open with cidr rule
sgs=$(aws ec2 describe-security-groups --output text --query 'SecurityGroups[*].Tags[*].Value')

# loop through found security groups
for sg in $sgs
do

	# call sub script
	echo $'\n' calling 	. ./closeports.sh $sg $port
	. ./closeports.sh $sg $port

done
