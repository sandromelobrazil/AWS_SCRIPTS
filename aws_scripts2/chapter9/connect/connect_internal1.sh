#!/bin/bash

# open an ssh session to the chapter 9 internal1
# which has keys enabled
# using agent forwarding
# then automate the 'sudo su' password entry

# include chapter9 variables
cd ..
. ./vars.sh
cd connect

# set internal1 base name
iibn+=1

# show variables
echo bastion base name: $ibn
echo internal1 base name: $iibn
echo new SSHD port: $sshport
echo ssh user: $sshuser
echo bastion ssher password: $bastion_ssherpassword
echo bastion root password: $bastion_rootpassword
echo internal1 ssher password: $internal1_ssherpassword
echo internal1 root password: $internal1_rootpassword

echo "connecting to instance $iibn via $ibn on $sshport with user $sshuser"

# kill any ssh agents and start a new one
kill $(pgrep ssh-agent)
eval `ssh-agent -s`

# add internal keys to ssh agent
cd ../internal/credentials
ssh-add -D
ssh-add internal1.pem
cd ../../connect

# get my ip
myip=$(curl http://checkip.amazonaws.com/)
echo myip=$myip

# get ip of server
ip_address=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values="$ibn" --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

# allow ssh in bastion sg
bastionsgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$ibn"sg --output text --query 'SecurityGroups[*].GroupId')
echo bastionsgid=$bastionsgid
aws ec2 authorize-security-group-ingress --group-id $bastionsgid --protocol tcp --port $sshport --cidr $myip/32

# allow ssh access from bastion to internal1
internal1sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$iibn"sg --output text --query 'SecurityGroups[*].GroupId')
echo internal1sgid=$internal1sgid
aws ec2 authorize-security-group-ingress --group-id $internal1sgid --source-group $bastionsgid --protocol tcp --port $sshport

# get an mfa code
read -s -p "mfa code:" mfacode

# make and run expect script
# use timeout -1 for no timeout
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -p $sshport -A $sshuser@$ip_address" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$bastion_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"ssh -p $sshport -i internal1.pem $sshuser@10.0.0.11\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"password for root:\"" >> expect.sh
echo "send \"$internal1_rootpassword\n\"" >> expect.sh
echo "interact" >> expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# script now waits for triple 'exit'
# one for internal1 'sudo su', one for internal1 ssh, one for bastion ssh

# remove internal keys from ssh agent
ssh-add -D

# kill it
kill $(pgrep ssh-agent)

# remove bastion ssh in sg
aws ec2 revoke-security-group-ingress --group-id $bastionsgid --protocol tcp --port $sshport --cidr $myip/32

# remove internal1 ssh access from bastion
aws ec2 revoke-security-group-ingress --group-id $internal1sgid --source-group $bastionsgid --protocol tcp --port $sshport

echo "revoked sg access"
