#!/bin/bash

# this script is run on the Bastion
# it prepares the scripts to be run on internal2
# which will harden SSH, set up SSH daily logging,
# set up SSH MFA and disable password-less sudo su

# include variables
. ./../vars.sh

# name and ipaddress for internal2
ibn=internal2
ip_address=10.0.0.12

# show variables
echo internal2 variables
echo ibn: $ibn
echo ip address: $ip_address
echo new SSHD port: $sshport
echo ssh user: $sshuser
echo ssher password: $internal2_ssherpassword
echo root password: $internal2_rootpassword

# wait for ssh to work
echo -n "waiting for ssh"
while ! ssh -i "$ibn".pem -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ec2-user@$ip_address > /dev/null 2>&1 true; do
 echo -n . ; sleep 5;
done; echo " ssh ok"

# remove old files
rm -f install.sh
rm -f sshd_config

# sed the root install script
sed -e "s/SEDsshuserSED/$sshuser/g" -e "s/SEDssherpasswordSED/$internal2_ssherpassword/g" -e "s/SEDrootpasswordSED/$internal2_rootpassword/g" install_template.sh > install.sh

# sed the sshd_config file
sed -e "s/SEDsshportSED/$sshport/g" -e "s/SEDsshuserSED/$sshuser/g" sshd_config_template > sshd_config

# make the script executable
chmod +x install.sh

# send required files
echo "transferring files"
scp -i "$ibn".pem install.sh ec2-user@$ip_address:
scp -i "$ibn".pem sshd_config ec2-user@$ip_address:
scp -i "$ibn".pem rsyslog.conf ec2-user@$ip_address:
echo "transferred files"

# remove sent files
rm -f install.sh
rm -f sshd_config

# run the install script
ssh -i "$ibn".pem -t -o ConnectTimeout=60 -o BatchMode=yes ec2-user@$ip_address sudo ./install.sh

echo
echo now install the Google Authenticator App on a smartphone
echo find the MFA KEY in the output above
echo and create an account on the App with Manual Entry
echo call it INTERNAL2
echo

echo make.sh for internal2 finished
