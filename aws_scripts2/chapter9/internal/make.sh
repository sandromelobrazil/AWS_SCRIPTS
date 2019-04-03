#!/bin/bash

# makes an ec2 instance with no Public IP Address
# attaches a security group
# does no configuration

# call from chapter9/internal directory
# expects 2 arguments:
# basename for the server (used for names and tags)
# internal ip address
# eg ./make.sh internal1 10.0.0.11

# include chapter9 variables
cd ..
. ./vars.sh
cd internal

# show variables
echo AMI: $baseami
echo VPC name: $vpcname

# make a new keypair
echo "making keypair"
rm credentials/"$1".pem
aws ec2 delete-key-pair --key-name "$1"
aws ec2 create-key-pair --key-name "$1" --query 'KeyMaterial' --output text > credentials/"$1".pem
chmod 600 credentials/"$1".pem
echo "$1" keypair made

# get the vpc id
vpc_id=$(aws ec2 describe-vpcs --filters Name=tag-key,Values=vpcname Name=tag-value,Values=$vpcname --output text --query 'Vpcs[*].VpcId')
echo vpc_id=$vpc_id

# make a security group
sgid=$(aws ec2 create-security-group --group-name "$1"sg --description "$1 security group" --vpc-id $vpc_id --output text --query 'GroupId')
# tag it
aws ec2 create-tags --resources $sgid --tags Key=sgname,Value="$1"sg
# now get the security group id again by using the tag
sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$1"sg --output text --query 'SecurityGroups[*].GroupId')
echo sgid=$sgid

# get a vpc subnet
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=tag-key,Values=subnet Name=tag-value,Values=1 --output text --query 'Subnets[*].SubnetId')
echo subnet_id=$subnet_id

# make the instance
instance_id=$(aws ec2 run-instances --image $baseami --key "$1" --security-group-ids $sgid --instance-type t2.micro --subnet-id $subnet_id --no-associate-public-ip-address --private-ip-address $2 --output text --query 'Instances[*].InstanceId')
echo instance_id=$instance_id

# tag the instance (so we can get it later)
aws ec2 create-tags --resources $instance_id --tags Key=instancename,Value="$1"

# wait for it
echo -n "waiting for instance"
while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
 echo -n . ; sleep 3;
done; echo " $state"

echo created internal server $1 with private ip $2
