#!/bin/bash

# open an ssh session to a server
# opens the associated Security Group port
# exit from ssh to remove the Security Group ingress rule

# call with one parameter, the tag name for the server
# eg if the server is tagged as [Name=server1]:
# ./connectsshbytag.sh server1

# does not assume each key is only used for one server
# does not assume server has only one security group

# assumes that if the key name for the server is eg serverkey, the file serverkey.pem is in the same directory as the script

# ssh port on server
sshport=22
# ssh user to connect with
sshuser=ec2-user

echo connecting ssh to $1 on $sshport with user $sshuser

# get my IP
myip=$(curl -s http://checkip.amazonaws.com/)
echo my IP is $myip

# get ip of server
# use 'Name=instance-state-name,Values=running'
# in case you just deleted an instance with the same key...
ip_address=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=$1 Name=instance-state-name,Values=running --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo connecting to $ip_address

# get security group id of server
sgid=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=$1 Name=instance-state-name,Values=running --output text --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId')
echo security group id is $sgid

# if multiple ids, only use the first with
sgids=($sgid)
sgid=${sgids[0]}
echo security group id is $sgid

# get key name for server
keyname=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=$1 Name=instance-state-name,Values=running --output text --query 'Reservations[*].Instances[*].KeyName')
echo connecting with key $keyname

# allow ssh in sg
echo authorising ingress
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32 --output text

echo ssh command:
echo ssh -i $keyname.pem -p $sshport $sshuser@$ip_address

# wait for ssh
echo -n "waiting for ssh"
while ! ssh -i $keyname.pem -p $sshport -o ConnectTimeout=5 -o BatchMode=yes $sshuser@$ip_address > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ok"

# connect
ssh -i $keyname.pem -p $sshport $sshuser@$ip_address

# exit ssh to close the security group port

# remove ssh in sg
echo revoking ingress
aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32 --output text
