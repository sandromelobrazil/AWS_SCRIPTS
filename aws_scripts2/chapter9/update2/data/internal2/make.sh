#!/bin/bash

# this script is run on the Bastion
# it prepares the scripts to be run on internal2
# which will do a yum update and update a phantom webroot
# internal2 now has SSH MFA and 'sudo su' password

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

# make the script executable
chmod +x install.sh

# make the zip
zip -r upload.zip install.sh webroot

# make and run expect script to upload zip
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "send_user \"MFA code for internal2: \"" >> expect.sh
echo "expect_user -re \"(.*)\n\"" >> expect.sh
echo "spawn scp -P $sshport -o PubkeyAuthentication=no -o StrictHostKeyChecking=no upload.zip $sshuser@$ip_address:" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$internal2_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo 'send $expect_out(1,string)\n' >> expect.sh
echo "interact" >> expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# delete the zip
rm -f upload.zip

# use expect to unzip and run install.sh
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "send_user \"MFA code for internal2: \"" >> expect.sh
echo "expect_user -re \"(.*)\n\"" >> expect.sh
echo "spawn ssh -p $sshport -o PubkeyAuthentication=no $sshuser@$ip_address" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$internal2_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo 'send $expect_out(1,string)\n' >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"password for root:\"" >> expect.sh
echo "send \"$internal2_rootpassword\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh

echo "send \"rm -f -r upload\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mkdir upload\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"mv upload.zip upload\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"cd upload\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"unzip upload.zip\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"ls -al\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"chmod +x install.sh\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh

# we can run install.sh and expect output
# because install.sh doesn't need user input
echo "send \"./install.sh\n\"" >> expect.sh
echo "expect \"finished install.sh on internal 2\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh
echo "interact" >> expect.sh

chmod +x expect.sh
./expect.sh
rm expect.sh

echo make.sh for internal2 finished
