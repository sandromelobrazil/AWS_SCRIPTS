#!/bin/bash

# shared variables for ALL scripts in ALL chapters

# this may change so find the latest from the aws console
# 'EC2' > 'Launch Instance' and copy the AMI ID
# must match the region used in 'aws configure'
# as of publishing, the following were valid:
# us-east-1 ami-1ecae776
# us-west-1 ami-d114f295
# us-west-2 ami-e7527ed7
# eu-west-1 ami-a10897d6
# eu-central-1 ami-a8221fb5
# ap-southeast-1 ami-68d8e93a
# ap-southeast-2 ami-fd9cecc7
# ap-northeast-1 ami-cbf90ecb
# sa-east-1 ami-b52890a8
# Amazon Linux AMI, HVM (ap-southeast-1)
baseami=ami-68d8e93a

# the name of the VPC to launch into
# see Appendix A
vpcname=MYVPC

# zones are sub regions
# must match the region used in 'aws configure'
# normally, zones are the same with a, b, c appended
# as of publishing, the following were valid:
# us-east-1 a b c e (ie us-east-1a us-east-1b us-east-1c us-east-1e)
# us-west-1 a c
# us-west-2 a b c
# eu-west-1 a b c
# eu-central-1 a b
# ap-southeast-1 a b
# ap-southeast-2 a b
# ap-northeast-1 a c
# sa-east-1 a b c
deployzone=ap-southeast-1a
deployzone2=ap-southeast-1b

# SSH defaults to port 22
# this is changed to a new port as defined below
sshport=38142

# the email address to send sshd logs to
emailaddress=user@youremail.com

# the new ssh username
sshuser=ssher
