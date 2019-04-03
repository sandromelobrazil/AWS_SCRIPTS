#!/bin/bash

# use this script to get access to a bricked server volume
# so you can fix whatever is wrong

# the tag of the server which is broken
# if you used appendixe/make.sh, this is 'brick'
brickibn=brick
echo brickibn=$brickibn

# get the instance id
brickid=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=$brickibn Name=instance-state-name,Values=running --output text --query 'Reservations[*].Instances[*].InstanceId')
echo brickid=$brickid

# get the volume id
volid=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=$brickibn --output text --query 'Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId')
echo volid=$volid

# stop the bricked instance
aws ec2 stop-instances --instance-ids $brickid

# wait for it to stop
echo -n "waiting for instance stop"
while state=$(aws ec2 describe-instances --instance-ids $brickid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" != "stopped"; do
 echo -n . ; sleep 3;
done; echo " $state"

# detach ebs volume from bricked instance
aws ec2 detach-volume --volume-id $volid --instance-id $brickid

# wait for detachment
echo -n "waiting for volume detach"
while state=$(aws ec2 describe-volumes --volume-ids $volid --output text --query 'Volumes[*].State'); test "$state" != "available"; do
 echo -n . ; sleep 3;
done; echo " detached"

# now make a 'debug' instance

# include globals
. ./../globals.sh

# tag for unbricker instance
ibn=unbricker

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

# make the unbricker instance
unbrickid=$(aws ec2 run-instances --image $baseami --key "$ibn" --security-group-ids $sgid --instance-type t2.micro --subnet-id $subnet_id --associate-public-ip-address --output text --query 'Instances[*].InstanceId')
echo unbrickid=$unbrickid

# tag the instance (so we can get it later)
aws ec2 create-tags --resources $unbrickid --tags Key=instancename,Value="$ibn"

# wait for it
echo -n "waiting for instance"
while state=$(aws ec2 describe-instances --instance-ids $unbrickid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
 echo -n . ; sleep 3;
done; echo " $state"

# get the new instance's public ip address
ip_address=$(aws ec2 describe-instances --instance-ids $unbrickid --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo ip_address=$ip_address

# wait for ssh to work
echo -n "waiting for ssh"
while ! ssh -i "$ibn".pem -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ec2-user@$ip_address > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ssh ok"

# attach the volume to the unbricker
aws ec2 attach-volume --volume-id $volid --instance-id $unbrickid --device /dev/xvdf

# wait for attachment
echo -n "waiting for volume attach"
while state=$(aws ec2 describe-volumes --volume-ids $volid --output text --query 'Volumes[*].Attachments[*].State'); test "$state" != "attached"; do
 echo -n . ; sleep 3;
done; echo " $state"

# ssh to the unbricker box and fix the sshd_config file
echo ssh in and fix sshd_config
# make and run expect script
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -i "$ibn".pem ec2-user@$ip_address" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"lsblk\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mkdir /brick\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mount /dev/xvdf1 /brick\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sed -e 's/Port X/Port 22/g' /brick/etc/ssh/sshd_config > /brick/etc/ssh/sshd_config2\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mv -f /brick/etc/ssh/sshd_config2 /brick/etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"chown root:root /brick/etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"chmod 600 /brick/etc/ssh/sshd_config\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "interact" >> expect.sh
cat expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# stop the unbricker
aws ec2 stop-instances --instance-ids $unbrickid

# wait for it to stop
echo -n "waiting for instance stop"
while state=$(aws ec2 describe-instances --instance-ids $unbrickid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" != "stopped"; do
 echo -n . ; sleep 3;
done; echo " $state"

# detach ebs volume from unbricker
aws ec2 detach-volume --volume-id $volid --instance-id $unbrickid

# wait for detachment
echo -n "waiting for volume detach"
while state=$(aws ec2 describe-volumes --volume-ids $volid --output text --query 'Volumes[*].State'); test "$state" != "available"; do
 echo -n . ; sleep 3;
done; echo " detached"

# attach volume to brick
aws ec2 attach-volume --volume-id $volid --instance-id $brickid --device /dev/xvda

# wait for attachment
echo -n "waiting for volume attach"
while state=$(aws ec2 describe-volumes --volume-ids $volid --output text --query 'Volumes[*].Attachments[*].State'); test "$state" != "attached"; do
 echo -n . ; sleep 3;
done; echo " $state"

# start the bricked instance
aws ec2 start-instances --instance-ids $brickid

# wait for it to start
echo -n "waiting for instance start"
while state=$(aws ec2 describe-instances --instance-ids $brickid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" != "running"; do
 echo -n . ; sleep 3;
done; echo " $state"

# terminate unbricker
aws ec2 terminate-instances --instance-ids $unbrickid

# wait for termination
echo -n "waiting for instance termination"
while state=$(aws ec2 describe-instances --instance-ids $unbrickid --output text --query 'Reservations[*].Instances[*].State.Name'); test "$state" != "terminated"; do
 echo -n . ; sleep 3;
done; echo " $state"

# delete unbricker key
rm "$ibn".pem
aws ec2 delete-key-pair --key-name "$ibn"

# delete unbricker security group
aws ec2 delete-security-group --group-id $sgid

echo brick fixed and unbricker terminated

# ssh to the fixed box
# get the new instance's public ip address
brickip=$(aws ec2 describe-instances --instance-ids $brickid --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo brickip=$brickip

# wait for ssh to work
echo -n "waiting for ssh"
while ! ssh -i "$brickibn".pem -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ec2-user@$brickip > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ssh ok"

ssh -i "$brickibn".pem ec2-user@$brickip
