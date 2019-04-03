#!/bin/bash

# this script updates the 2 internal servers
# the updates are slightly more complex than in chapter9/update

# it will zip up all the update/internal* folders
# eg internal1, internal2, ..., internalN
# and install.sh and a generated vars.sh
# then send this zip to the bastion with scp
# then install.sh will be run on the bastion
 
# this script needs to be called from chapter9/update directory
# with ./update.sh

# include chapter9 variables
cd ..
. ./vars.sh
cd update2

# get my ip
myip=$(curl http://checkip.amazonaws.com/)
echo myip=$myip

# get ip of bastion
bastionip=$(aws ec2 describe-instances --filters Name=tag-key,Values=instancename Name=tag-value,Values=bastion --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
echo bastionip=$bastionip

# allow ssh in sg
bastionsgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=bastionsg --output text --query 'SecurityGroups[*].GroupId')
echo bastionsgid=$bastionsgid
aws ec2 authorize-security-group-ingress --group-id $bastionsgid --protocol tcp --port $sshport --cidr $myip/32

# allow ssh access from bastion to internal1
internal1sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=internal1sg --output text --query 'SecurityGroups[*].GroupId')
echo internal1sgid=$internal1sgid
aws ec2 authorize-security-group-ingress --group-id $internal1sgid --source-group $bastionsgid --protocol tcp --port $sshport

# allow ssh access from bastion to internal2
internal2sgid=$(aws ec2 describe-security-groups --filters Name=tag-key,Values=sgname Name=tag-value,Values=internal2sg --output text --query 'SecurityGroups[*].GroupId')
echo internal2sgid=$internal2sgid
aws ec2 authorize-security-group-ingress --group-id $internal2sgid --source-group $bastionsgid --protocol tcp --port $sshport

# allow squid access from internal1 to bastion
aws ec2 authorize-security-group-ingress --group-id $bastionsgid --source-group $internal1sgid --protocol tcp --port 3128

# allow squid access from internal2 to bastion
aws ec2 authorize-security-group-ingress --group-id $bastionsgid --source-group $internal2sgid --protocol tcp --port 3128

# make a vars.sh file from globals.sh and chapter9/vars.sh
# we are in chapter9/update directory
cat ../../globals.sh > data/vars.sh
tail -n +5 ../vars.sh >> data/vars.sh
chmod +x data/vars.sh

# make the zip
cd data
zip -r upload.zip vars.sh install.sh internal*
cd ..

# remove temporary vars.sh file
rm -f data/vars.sh

# get an mfa code
read -s -p "MFA code for Bastion:" mfacode

# make and run expect script to upload zip
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn scp -P $sshport -o PubkeyAuthentication=no data/upload.zip $sshuser@$bastionip:" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$bastion_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode\n\"" >> expect.sh
echo "interact" >> expect.sh
#cat expect.sh
chmod +x expect.sh
./expect.sh
rm expect.sh

# remove zip
rm -f data/upload.zip

# kill any ssh agents and start a new one
kill $(pgrep ssh-agent)
eval `ssh-agent -s`

# add internal1 key to ssh agent
# internal2 is now on MFA
cd ../internal/credentials
ssh-add -D
ssh-add internal1.pem
cd ../../configure

# get an mfa code
read -s -p "MFA code for Bastion:" mfacode

# make and run expect script to run zip
# the ssh -A option enables agent forwarding
# note agent forwarding does not work if you 'sudo su'
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn ssh -p $sshport -A -o PubkeyAuthentication=no $sshuser@$bastionip" >> expect.sh
echo "expect \"Password:\"" >> expect.sh
echo "send \"$bastion_ssherpassword\n\"" >> expect.sh
echo "expect \"Verification code:\"" >> expect.sh
echo "send \"$mfacode\n\"" >> expect.sh

# we use a little trick to sudo su and then exit
# so we can use it later with no password
echo "expect \"]\"" >> expect.sh
echo "send \"sudo su\n\"" >> expect.sh
echo "expect \"password for root:\"" >> expect.sh
echo "send \"$bastion_rootpassword\n\"" >> expect.sh
echo "expect \"]\"" >> expect.sh
echo "send \"exit\n\"" >> expect.sh

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
echo "send \". ./install.sh\n\"" >> expect.sh

# by using 'interact' here and not 'expect'ing anything
# install.sh can use expect normally and get user input for mfa codes
echo "interact" >> expect.sh

# however, any further expects or send won't now work
# eg you can't do this:
#echo "expect \"]\"" >> expect.sh
#echo "send \"exit\n\"" >> expect.sh
#echo "interact" >> expect.sh

# this is why we call install.sh with
# . ./install.sh (not ./install.sh)
# so that it can 'exit' ssh

chmod +x expect.sh
./expect.sh
rm expect.sh

# remove internal keys from ssh agent
ssh-add -D

# kill it
kill $(pgrep ssh-agent)

# revoke ssh to bastion
aws ec2 revoke-security-group-ingress --group-id $bastionsgid --protocol tcp --port $sshport --cidr $myip/32

# revoke ssh between bastion and internal1
aws ec2 revoke-security-group-ingress --group-id $internal1sgid --source-group $bastionsgid --protocol tcp --port $sshport

# revoke ssh between bastion and internal2
aws ec2 revoke-security-group-ingress --group-id $internal2sgid --source-group $bastionsgid --protocol tcp --port $sshport

# revoke squid access from internal1 to bastion
aws ec2 revoke-security-group-ingress --group-id $bastionsgid --source-group $internal1sgid --protocol tcp --port 3128

# revoke access from internal2 to bastion
aws ec2 revoke-security-group-ingress --group-id $bastionsgid --source-group $internal2sgid --protocol tcp --port 3128

echo revoked sg access

echo configuration done
