#!/bin/bash

# this script is run on the Bastion
# it prepares the scripts to be run on internal1
# which will do a yum update
# and delete the ec2-user

# include variables
. ./../vars.sh

# name and ipaddress for internal1
ibn=internal1
ip_address=10.0.0.11

# show variables
echo internal1 variables
echo ibn: $ibn
echo ip address: $ip_address
echo new SSHD port: $sshport
echo ssh user: $sshuser
echo ssher password: $internal1_ssherpassword
echo root password: $internal1_rootpassword

# make the script executable
chmod +x install.sh

# send required files
echo "transferring files"
scp -i "$ibn".pem -P $sshport -o StrictHostKeyChecking=no install.sh $sshuser@$ip_address:
echo "transferred files"

# use expect to run the script
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -i $ibn.pem -p $sshport $sshuser@$ip_address" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"password for root:\"" >> expect.sh
echo "send \"$internal1_rootpassword\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"./install.sh\n\"" >> expect.sh
echo "expect \"finished install.sh on internal 1\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "interact" >> expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

echo make.sh for internal1 finished
