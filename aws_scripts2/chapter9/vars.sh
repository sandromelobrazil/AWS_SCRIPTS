#!/bin/bash

# include globals
. ./../globals.sh

# shared variables for scripts in chapter9

# the base name for the bastion instance
# this string is used for key name, instance and sg names and tags
ibn=bastion

# the base name for internal instances
# this string is used for key name, instance and sg names and tags
iibn=internal

# bastion password for ssher
bastion_ssherpassword=1234

# bastion password for root
bastion_rootpassword=123456

# password for ssher on internal1
internal1_ssherpassword=1111

# password for root on internal1
internal1_rootpassword=111111

# password for ssher on internal2
internal2_ssherpassword=2222

# password for root on internal2
internal2_rootpassword=222222
