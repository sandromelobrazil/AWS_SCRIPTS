#!/bin/bash

# this script makes a simple instance
# then ssh in and breaks ssh
# it bricks the instance

# include globals
. ./../globals.sh

# base name for this instance
ibn=brick

# show variables
echo AMI: $baseami
echo instance base name: $ibn
echo VPC name: $vpcname

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

# ssh to the box and screw up the sshd config file
echo ssh in and screw up sshd_config
# make and run expect script
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -i "$ibn".pem ec2-user@$ip_address" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sed -e 's/#Port 22/Port X/g' /etc/ssh/sshd_config > /etc/ssh/sshd_config2\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mv -f /etc/ssh/sshd_config2 /etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"chown root:root /etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"chmod 600 /etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"/etc/init.d/sshd restart\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sleep 5\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "interact" >> expect.sh
cat expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# test ssh (won't work)
ssh -i "$ibn".pem ec2-user@$ip_address

echo now use unbrick.sh to fix it...
