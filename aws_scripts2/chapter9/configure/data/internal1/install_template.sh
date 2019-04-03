#!/bin/bash

# this script changes the ssh user to ssher
# it hardens ssh, but keeps key based auth
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

# set the max concurrent ssh sessions
echo "SEDsshuserSED - maxlogins 1" >> /etc/security/limits.conf

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
