#!/bin/bash

# this script needs to be run on the instance
# simple demonstration of how to run a script to update an internal server

echo running install.sh on internal 1

yum -y update

rm -f -r /var/www/html
mkdir -p /var/www/html
mv webroot/* /var/www/html
ls /var/www/html

echo finished install.sh on internal 1
