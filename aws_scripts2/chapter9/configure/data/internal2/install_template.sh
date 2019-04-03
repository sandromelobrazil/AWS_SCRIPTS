#!/bin/bash

# this script changes the ssh user to ssher
# it hardens ssh
# it configures sshd to use a password and MFA
# it disables password-less 'sudo su'
# and requires the root password to do so
# it sets up rsyslog forwarding for authpriv.* to bastion
# it sets up yum to use squid on bastion

# the following strings are replaced:
# SEDsshuserSED
# SEDssherpasswordSED
# SEDrootpasswordSED

# configure and update yum
echo "proxy=http://10.0.0.10:3128" >> /etc/yum.conf
yum -y update

# add ssher user
groupadd SEDsshuserSED
useradd -g SEDsshuserSED SEDsshuserSED

# install expect
yum install -y expect

# change ssher's password with expect
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

# change root's password with expect
echo "#!/usr/bin/expect -f" > expect.sh
echo "set timeout -1" >> expect.sh
echo "spawn passwd root" >> expect.sh
echo "expect \"New password:\"" >> expect.sh
echo "send \"SEDrootpasswordSED\n\";" >> expect.sh
echo "expect \"new password:\"" >> expect.sh
echo "send \"SEDrootpasswordSED\n\";" >> expect.sh
echo "interact" >> expect.sh
# run it
chmod +x expect.sh
./expect.sh
# remove it
rm -f expect.sh

# erase expect
yum erase -y expect

# disable passwordless 'sudo su'
echo "SEDsshuserSED ALL = ALL" > /etc/sudoers.d/cloud-init

# require root password for 'sudo su' (not sshers's)
echo "Defaults targetpw" >> /etc/sudoers.d/cloud-init

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

# configure rsyslog
cd /home/ec2-user
mv -f rsyslog.conf /etc/rsyslog.conf
chown root:root /etc/rsyslog.conf
chmod 400 /etc/rsyslog.conf

# delete this script
rm -f /home/ec2-user/install.sh
