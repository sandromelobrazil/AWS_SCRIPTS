#!/bin/bash
# script to do a daily YUM update
# copy to /etc/cron.daily/
YUM=/usr/bin/yum
$YUM -y -R 120 -d 0 -e 0 update yum
$YUM -y -R 10 -e 0 -d 0 update
