#!/bin/bash

# this script tests out security group port closing scripts
# it makes 2 security groups, adds some rules, then tests the close scripts
# finally, it deletes the security groups
# for this test, for simplicity, we are not using a vpc

echo $'\n' making new sgs and rules $'\n'

# make my1 sg
my1sgid=$(aws ec2 create-security-group --group-name my1sg --description "my1 security group" --output text --query 'GroupId')
# tag it
aws ec2 create-tags --resources $my1sgid --tags Key=sgname,Value=my1sg
# get the sg id by tag
my1sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=my1sg --output text --query 'SecurityGroups[*].GroupId')
echo my1sgid=$my1sgid

# make my2 sg
my2sgid=$(aws ec2 create-security-group --group-name my2sg --description "my2 security group" --output text --query 'GroupId')
# tag it
aws ec2 create-tags --resources $my2sgid --tags Key=sgname,Value=my2sg
# get the sg id by tag
my2sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=my2sg --output text --query 'SecurityGroups[*].GroupId')
echo my2sgid=$my2sgid

# create some inbound rules on tcp port 22 (they are unattached sgs so no security issues...)
# my1: from 0.0.0.0/0; from 10.0.10.0/24; from 192.168.1.1/32
# my2: from 10.0.10.0/24; from my1
# also create some tcp port 80 rules, to check they are unaffected
# my1: from 0.0.0.0/0
# my2: from 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-id $my1sgid --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $my1sgid --protocol tcp --port 22 --cidr 10.0.10.0/24
aws ec2 authorize-security-group-ingress --group-id $my1sgid --protocol tcp --port 22 --cidr 192.168.1.1/32

aws ec2 authorize-security-group-ingress --group-id $my2sgid --protocol tcp --port 22 --cidr 10.0.10.0/24
aws ec2 authorize-security-group-ingress --group-id $my2sgid --protocol tcp --port 22 --source-group $my1sgid

aws ec2 authorize-security-group-ingress --group-id $my1sgid --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $my2sgid --protocol tcp --port 80 --cidr 0.0.0.0/0

# describe the groups
echo $'\n' describing new sgs $'\n'
aws ec2 describe-security-groups --group-id $my1sgid --output text
aws ec2 describe-security-groups --group-id $my2sgid --output text

# lets close cidr 22s in my2sg
echo $'\n' closing 22 cidrs in my2sg$ with . ./closeports.sh my2sg 22 $'\n'
. ./closeports.sh my2sg 22

# then describe my2sg
echo $'\n' describing my2sg $'\n'
aws ec2 describe-security-groups --group-id $my2sgid --output text
echo $'\n' note 'IPRANGES	10.0.10.0/24' is no longer listed

# make my2sg rules again
echo $'\n' remaking my2sg 10.0.10.0/24:22 rule
aws ec2 authorize-security-group-ingress --group-id $my2sgid --protocol tcp --port 22 --cidr 10.0.10.0/24

# describe my2sg again
echo $'\n' describing my2sg $'\n'
aws ec2 describe-security-groups --group-id $my2sgid --output text

# close all cidr 22s in all sgs
echo $'\n' closing 22 cidrs in all sgs with . ./closeportsallsgs.sh 22
. ./closeportsallsgs.sh 22
echo $'\n' finished . ./closeportsallsgs.sh 22

# describe the groups
echo $'\n' describing after all closed $'\n'
aws ec2 describe-security-groups --group-id $my1sgid --output text
aws ec2 describe-security-groups --group-id $my2sgid --output text
echo $'\n' note there are no port 22 cidr rules

# delete the sgs
# first revoke the link between sgs (or they can't be deleted)
aws ec2 revoke-security-group-ingress --group-id $my2sgid --protocol tcp --port 22 --source-group $my1sgid
# now delete
aws ec2 delete-security-group  --group-id $my1sgid
aws ec2 delete-security-group  --group-id $my2sgid
echo $'\n' deleted groups
