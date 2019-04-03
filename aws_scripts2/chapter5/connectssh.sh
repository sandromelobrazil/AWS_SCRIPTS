#!/bin/bash

# open an ssh session to a server
# opens the associated Security Group port
# exit from ssh to remove the Security Group ingress rule

# call with one parameter, the key name for the server
# eg if you connect with server.pem use:
# ./connectssh.sh server

# assumes each key is only used for one server
# assumes server has only one security group

# ssh port on server
sshport=22
# ssh user to connect with
sshuser=ec2-user

echo connecting ssh to $1 on $sshport with user $sshuser

# get my IP
myip=$(curl -s http://checkip.amazonaws.com/)
echo my IP is $myip

# get ip of server
ip_address=$(aws ec2 describe-instances --filters Name=key-name,Values=$1 --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo connecting to $ip_address

# get security group id of server
sgid=$(aws ec2 describe-instances --filters Name=key-name,Values=$1 --output text --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId')
echo security group id is $sgid

# allow ssh in sg
echo authorising ingress
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32 --output text

echo ssh command:
echo ssh -i $1.pem -p $sshport $sshuser@$ip_address

# wait for ssh
echo -n "waiting for ssh"
while ! ssh -i $1.pem -p $sshport -o ConnectTimeout=5 -o BatchMode=yes $sshuser@$ip_address > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ok"

# now connect
ssh -i $1.pem -p $sshport $sshuser@$ip_address

# exit ssh to close the security group port

# remove ssh in sg
echo revoking ingress
aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32 --output text
