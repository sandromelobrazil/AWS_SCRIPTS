#!/bin/bash

# a script to send an email with the last days sshd log
# old log entries are moved to secureold

echo "." >> /var/log/secure
/usr/sbin/sendmail youremail@address.com < /var/log/secure
cat /var/log/secure >> /var/log/secureold
echo "" > /var/log/secure
chown root:root /var/log/secureold
chmod 600 /var/log/secureold
