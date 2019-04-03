#!/bin/bash

# this script needs to be run on the instance as root
# it changes the ssh user to ssher
# it hardens sshd
# it sets up a daily email of the sshd log file

# the following strings are replaced:
# SEDsshuserSED
# SEDemailaddressSED

# update yum
yum -y update

# add ssher user
groupadd SEDsshuserSED
useradd -g SEDsshuserSED SEDsshuserSED

# actually, as we are still using ssh keys,
# we don't need to change ssher's password

# allow ssher to 'sudo su'
sed -e "s/ec2-user/SEDsshuserSED/g" /etc/sudoers.d/cloud-init > /etc/sudoers.d/cloud-init2
cat /etc/sudoers.d/cloud-init2 > /etc/sudoers.d/cloud-init
rm /etc/sudoers.d/cloud-init2
cat /etc/sudoers.d/cloud-init

# move the ssh key
cd /home/SEDsshuserSED
mkdir .ssh
chown SEDsshuserSED:SEDsshuserSED .ssh
chmod 700 .ssh
ls -al
mv /home/ec2-user/.ssh/authorized_keys .ssh
chown SEDsshuserSED:SEDsshuserSED .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
ls -al .ssh

# update sshd config
cd /home/ec2-user
mv sshd_config /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

# set the max concurrent ssh sessions
echo "SEDsshuserSED - maxlogins 1" >> /etc/security/limits.conf

# restart sshd
# careful, sshd doesn't seem to like
# being restarted just as you end an ssh session
/etc/init.d/sshd restart
sleep 5

# set up email logging
mv emailsshlog.sh /root/emailsshlog.sh
chown root:root /root/emailsshlog.sh
chmod 500 /root/emailsshlog.sh

# run daily at 12:05am
line="5 0 * * * /root/emailsshlog.sh"
(crontab -u root -l; echo "$line" ) | crontab -u root -

# send immediate email for sudo use
echo 'Defaults mailto="SEDemailaddressSED",mail_always' >> /etc/sudoers.d/cloud-init

# send immediate email for root signin
echo "echo Subject: Root Access\$'\n'\$(who) | sendmail SEDemailaddressSED" >> /root/.bashrc

# delete this script
rm -f install.sh
