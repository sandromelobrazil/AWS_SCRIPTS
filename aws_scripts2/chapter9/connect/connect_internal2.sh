#!/bin/bash

# open an ssh session to the chapter 9 internal2
# which is using ssh MFA
# then automate the 'sudo su' password entry

# include chapter9 variables
cd ..
. ./vars.sh
cd connect

# set internal2 base name
iibn+=2

# show variables
echo bastion base name: $ibn
echo internal2 base name: $iibn
echo new SSHD port: $sshport
echo ssh user: $sshuser
echo bastion ssher password: $bastion_ssherpassword
echo bastion root password: $bastion_rootpassword
echo internal2 ssher password: $internal2_ssherpassword
echo internal2 root password: $internal2_rootpassword

echo "connecting to instance $iibn via $ibn on $sshport with user $sshuser"

# remove any ssh agent keys
ssh-add -D

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

# allow ssh access from bastion to internal2
internal2sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$iibn"sg --output text --query 'SecurityGroups[*].GroupId')
echo internal2sgid=$internal2sgid
aws ec2 authorize-security-group-ingress --group-id $internal2sgid --source-group $bastionsgid --protocol tcp --port $sshport

# get mfa codes
read -s -p "bastion mfa code:" mfacode1
echo
read -s -p "internal2 mfa code:" mfacode2

# make and run expect script
# use timeout -1 for no timeout
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -p $sshport $sshuser@$ip_address" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$bastion_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode1\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"ssh -p $sshport $sshuser@10.0.0.12\n\"" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$internal2_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode2\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"password for root:\"" >> expect.sh
echo "send \"$internal2_rootpassword\n\"" >> expect.sh
echo "interact" >> expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# script now waits for triple 'exit'
# one for internal2 'sudo su', one for internal2 ssh, one for bastion ssh

# remove bastion ssh in sg
aws ec2 revoke-security-group-ingress --group-id $bastionsgid --protocol tcp --port $sshport --cidr $myip/32

# remove internal2 ssh access from bastion
aws ec2 revoke-security-group-ingress --group-id $internal2sgid --source-group $bastionsgid --protocol tcp --port $sshport

echo "revoked sg access"
