#!/bin/bash

# open an ssh session to a server
# which has keys disabled and MFA enabled
# as created by make.sh in this directory (chapter7)

# include chapter7 variables
. ./vars.sh

# show variables
echo instance base name: $ibn
echo new SSHD port: $sshport
echo ssh user: $sshuser
echo ssher password: $ssherpassword

# if you want to make this script standalone
# (ie not relying on vars.sh)
# comment out '. ./vars.sh' above and define the variables here, eg:
#ibn=sshpass
#sshport=38142
#sshuser=ssher
#ssherpassword=1234

# if you wanted to have a typed password,
# ie you don't want to encode the password in this script,
# you could use:
#read -s -p "ssher password:" ssherpassword
# also remove the declaration above

echo "connecting to instance $ibn on $sshport with user $sshuser"

myip=$(curl http://checkip.amazonaws.com/)
echo myip=$myip

# get ip of server
ip_address=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values="$ibn" --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

# allow ssh in sg
sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$ibn"sg --output text --query 'SecurityGroups[*].GroupId')
echo sgid=$sgid
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32

# get an mfa code
read -s -p "mfa code:" mfacode

# make and run expect script
# use timeout -1 for no timeout
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -p $sshport $sshuser@$ip_address" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode\n\"" >> expect.sh
echo "interact" >> expect.sh
chmod +x expect.sh
./expect.sh
rm -f expect.sh

# script now waits for 'exit'
# or double 'exit' if you 'sudo su'

# remove ssh in sg
aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32
echo "revoked sg access"
