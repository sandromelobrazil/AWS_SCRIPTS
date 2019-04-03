#!/bin/bash

# interactive script to change security credentials
# to the admin or connect role

# call with 1 argument: admin or connect, ie
# ./signin.sh admin
# ./signin.sh connect

# this script is a template to be searched and replaced by mfa_setup.sh
# replaced strings:
# arn:aws:iam::000000000000:role/assumer_adminrole
# arn:aws:iam::000000000000:role/assumer_connectrole
# arn:aws:iam::000000000000:mfa/assumer_mfa_device
# assumer

# the output from 'sed' can be found in chapter4/output/signin.sh
# signin.sh relies on nothing and can be moved anywhere

# this script only works if the current user is 'assumer'
# ie, signout.sh needs to have been called first

# the role arns we will be assuming
adminrolearn=arn:aws:iam::000000000000:role/assumer_adminrole
connectrolearn=arn:aws:iam::000000000000:role/assumer_connectrole

rolearn=none
if test "$1" = "admin"; then
	rolearn=$adminrolearn
elif test "$1" = "connect"; then
	rolearn=$connectrolearn
else
	echo 'usage: ./signin.sh <admin or connect>'
	exit
fi
# get the virtual mfa device serial
username=assumer
mfaserial=arn:aws:iam::000000000000:mfa/assumer_mfa_device

# prompt the user for an mfa code
read -p "Enter an MFA code for $username: " mfacode

# assume the role
# we need to get 3 values from this returned data but can only call the function once
# so we can't use '--query'
cred=$(aws sts assume-role --role-arn $rolearn --role-session-name rolesession --serial-number $mfaserial --token-code $mfacode --duration-seconds 3600 --output text)
echo $cred

# let's check we assumed the role ok
# perhaps we made a mistake with the mfa code
if test "$cred" = ""; then
	# it didn't work
	echo ensue you are signed in as the assumer user
	echo by running signout.sh
	echo or please retry with new mfa code
	echo assume role $1 FAILED
	exit
fi

# ok it worked, get the credentials
bits=($cred)
AccessKeyId=${bits[4]}
SecretAccessKey=${bits[6]}
SessionToken=${bits[7]}

# clear aws cli auth
export AWS_SECRET_KEY=
export AWS_ACCESS_KEY=
export AWS_DELEGATION_TOKEN=
rm ~/.aws/credentials

# now set aws credentials with the temporary ones received
echo [default] > ~/.aws/credentials
echo aws_access_key_id=$AccessKeyId >> ~/.aws/credentials
echo aws_secret_access_key=$SecretAccessKey >> ~/.aws/credentials
echo aws_session_token=$SessionToken >> ~/.aws/credentials
chmod 600 ~/.aws/credentials
# other options are in ~/.aws/config
# like region and output format
# but we don't need to touch this file

# now all aws commands will work for 1 hour
# after expiry, call signout.sh to reinstate the 'assumer user'
# and then run this script again if you need credentials again
echo $1 assumed SUCCESS
