#!/bin/bash

# makes an ec2 instance
# the ssh user is changed and ssh is hardened
# SSH Keys are retained

# include chapter6 variables
. ./vars.sh

# show variables
echo AMI: $baseami
echo instance base name: $ibn
echo VPC name: $vpcname
echo new SSHD port: $sshport
echo logging to email address: $emailaddress
echo sshuser: $sshuser

# get our ip from amazon
myip=$(curl http://checkip.amazonaws.com/)
echo myip=$myip

# make a new keypair
echo "making keypair"
rm "$ibn".pem
aws ec2 delete-key-pair --key-name "$ibn"
aws ec2 create-key-pair --key-name "$ibn" --query 'KeyMaterial' --output text > "$ibn".pem
chmod 600 "$ibn".pem
echo "$ibn" keypair made

# get the vpc id
vpc_id=$(aws ec2 describe-vpcs --filters Name=tag-key,Values=vpcname Name=tag-value,Values=$vpcname --output text --query 'Vpcs[*].VpcId')
echo vpc_id=$vpc_id

# make a security group
sgid=$(aws ec2 create-security-group --group-name "$ibn"sg --description "$ibn security group" --vpc-id $vpc_id --output text --query 'GroupId')
# tag it
aws ec2 create-tags --resources $sgid --tags Key=sgname,Value="$ibn"sg
# now get the security group id again by using the tag
sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values="$ibn"sg --output text --query 'SecurityGroups[*].GroupId')
echo sgid=$sgid

# allow ssh in on port 22 from our ip only
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 22 --cidr $myip/32

# get a vpc subnet
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=tag-key,Values=subnet Name=tag-value,Values=1 --output text --query 'Subnets[*].SubnetId')
echo subnet_id=$subnet_id

# make the instance
instance_id=$(aws ec2 run-instances --image $baseami --key "$ibn" --security-group-ids $sgid --instance-type t2.micro --subnet-id $subnet_id --associate-public-ip-address --output text --query 'Instances[*].InstanceId')
echo instance_id=$instance_id

# tag the instance (so we can get it later)
aws ec2 create-tags --resources $instance_id --tags Key=instancename,Value="$ibn"

# wait for it
echo -n "waiting for instance"
while state=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
 echo -n . ; sleep 3;
done; echo " $state"

# get the new instance's public ip address
ip_address=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

# wait for ssh to work
echo -n "waiting for ssh"
while ! ssh -i "$ibn".pem -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ec2-user@$ip_address > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ssh ok"

# remove old files
rm -f install.sh
rm -f emailsshlog.sh
rm -f sshd_config

# sed the install script
sed -e "s/SEDsshuserSED/$sshuser/g" -e "s/SEDemailaddressSED/$emailaddress/g" install_template.sh > install.sh

# sed the email logging script
sed -e "s/SEDemailaddressSED/$emailaddress/g" emailsshlog_template.sh > emailsshlog.sh

# sed the sshd_config file
sed -e "s/SEDsshportSED/$sshport/g" -e "s/SEDsshuserSED/$sshuser/g" sshd_config_template > sshd_config

# make the scripts executable
chmod +x install.sh
chmod +x emailsshlog.sh

# send required files
echo "transferring files"
scp -i "$ibn".pem install.sh ec2-user@$ip_address:
scp -i "$ibn".pem sshd_config ec2-user@$ip_address:
scp -i "$ibn".pem emailsshlog.sh ec2-user@$ip_address:
echo "transferred files"

# remove sent files
rm -f install.sh
rm -f emailsshlog.sh
rm -f sshd_config

# run the install script
ssh -i "$ibn".pem -t -o ConnectTimeout=60 -o BatchMode=yes ec2-user@$ip_address sudo ./install.sh

# drop the port 22 rule
aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port 22 --cidr $myip/32

# open up the new ssh port
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32

echo
echo now ssh to the box with:
echo ssh -i "$ibn".pem -p $sshport "$sshuser"@"$ip_address"
echo 'sudo su' still works
echo remove ec2-user with: userdel -r ec2-user

echo
echo while sshed in from one terminal, try again from another
echo you will get: Too many logins for 'ssher'.

echo
echo when finished, terminate the server or close the 22 inbound port
echo "eg aws ec2 revoke-security-group-ingress --group-id $sgid --protocol tcp --port $sshport --cidr $myip/32"
