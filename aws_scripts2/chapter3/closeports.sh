#!/bin/bash

# this script closes any cidr rules for the specified port for the specified security group
# call it with 2 arguments
# ./closeports <sg_tag_value> <port>
# eg ./closeports xxxsg 22 would close port 22 rules in xxx security group (tagged xxxsg)

# when we create a security group, we always tag it [sgname=xxxsg] with:
# aws ec2 create-tags --resources <security group id> --tags Key=sgname,Value=xxxsg

# read arguments
sgtag=$1
port=$2

# get the group id of the sg from the tag
sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=$sgtag --output text --query 'SecurityGroups[*].GroupId')
echo sgid=$sgid

echo closing any port $port inbound rules in sg $sgid tagged $sgtag

# get the cidrs for the ingress rule
rules=$(aws ec2 describe-security-groups --group-ids $sgid --output text --query 'SecurityGroups[*].IpPermissions')

# if no rules, quit
if test "$rules" = ""; then
	echo "no rules found, exiting"
	exit
fi

# rules will contain something like:
# 22 tcp 22
# IPRANGES 108.42.177.53/32
# IPRANGES 10.0.0.0/16
# 80 tcp 80
# IPRANGES 0.0.0.0/0

# luckily, aws returns all ipranges per port grouped together
	
# flag for if we are reading ipranges
reading=0
# loop returned lines
while read -r line; do
	# split the line up
	rulebits=($line)
	# check if if we are reading ssh port ipranges
	if [ $reading -eq 0 ] ; then
		# we are not reading ipranges
		# assuming port==22, check if '22 tcp 22'
		if [ ${rulebits[0]} == "$port" ] && [ ${rulebits[1]} == "tcp" ] && [ ${rulebits[2]} == "$port" ] ; then
			# found it
			reading=1			
		fi
	else
		# we are reading ipranges
		# check if first word is 'IPRANGES'
		if [ ${rulebits[0]} == "IPRANGES" ] ; then
			# found a cidr for open ssh port
			cidr=${rulebits[1]}
			echo found port $port open cidr $cidr closing...
			# close it
			aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port $port --cidr $cidr
		else
			# new port
			reading=0		
		fi
	fi
done <<< "$rules"
