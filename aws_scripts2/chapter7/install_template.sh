#!/bin/bash

# this script needs to be run on the instance as root
# it changes the ssh user to ssher
# it hardens ssh
# it configures sshd to use a password and MFA
# it sets up a daily email of the sshd log file

# the following strings are replaced:
# SEDsshuserSED
# SEDssherpasswordSED
# SEDemailaddressSED

# update yum
yum -y update

# add ssher user
groupadd SEDsshuserSED
useradd -g SEDsshuserSED SEDsshuserSED

# change ssher's password with expect
# install expect
yum install -y expect
# make expect script
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn passwd SEDsshuserSED" >> expect.sh
echo "expect \"New password:\"" >> expect.sh
echo "send \"SEDssherpasswordSED\n\";" >> expect.sh
echo "expect \"new password:\"" >> expect.sh
echo "send \"SEDssherpasswordSED\n\";" >> expect.sh
echo "interact" >> expect.sh
# run it
chmod +x expect.sh
./expect.sh
# remove it
rm -f expect.sh
# erase expect
yum erase -y expect

# allow ssher to 'sudo su'
sed -e "s/ec2-user/SEDsshuserSED/g" /etc/sudoers.d/cloud-init > /etc/sudoers.d/cloud-init2
cat /etc/sudoers.d/cloud-init2 > /etc/sudoers.d/cloud-init
rm /etc/sudoers.d/cloud-init2

# update sshd config
mv sshd_config /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

# remove sshd keys so ssher can't sign in with a key
rm -f /home/ec2-user/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys

# set the max concurrent ssh sessions
echo "SEDsshuserSED - maxlogins 1" >> /etc/security/limits.conf

# install mfa and pam modules
yum -y install google-authenticator.x86_64 pam.x86_64 pam-devel.x86_64

# update pam config
echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd

# run the google authenticator for ssher
cd /home/SEDsshuserSED
google-authenticator --time-based --disallow-reuse --force --rate-limit=1 --rate-time=60 --window-size=3 --quiet --secret=/home/SEDsshuserSED/.google_authenticator
chown SEDsshuserSED:SEDsshuserSED .google_authenticator
chmod 400 .google_authenticator

# delete last 4 GOOJ codes
head -n 6 .google_authenticator > .google_authenticator2
mv -f .google_authenticator2 .google_authenticator
chown SEDsshuserSED:SEDsshuserSED .google_authenticator
chmod 400 .google_authenticator

# print out the codes
bits=($(cat .google_authenticator))
echo MFA KEY is ${bits[0]}
echo MFA GOOJ is ${bits[11]}

# restart sshd
# careful, sshd doesn't seem to like
# being restarted just as you end an ssh session
/etc/init.d/sshd restart
sleep 5

# set up email logging
cd /home/ec2-user/
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
rm -f /home/ec2-user/install.sh
