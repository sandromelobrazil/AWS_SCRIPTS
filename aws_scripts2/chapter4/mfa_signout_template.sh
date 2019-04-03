#!/bin/bash

# script to change security credentials to the 'assumer user'
# that is, a user with no privileges except for 'aws sts assume-role'

# this script is a template to be searched and replaced by mfa_setup.sh
# replaced strings:
# SEDAccessKeyIdSED
# SEDSecretAccessKeySED
# SEDusernameSED

# the output from 'sed' can be found in chapter4/output/signout.sh
# signout.sh relies on nothing and can be moved anywhere

# the assumer user's credentials
AccessKeyId=SEDAccessKeyIdSED
SecretAccessKey=SEDSecretAccessKeySED

# clear aws cli auth
export AWS_SECRET_KEY=
export AWS_ACCESS_KEY=
export AWS_DELEGATION_TOKEN=
rm ~/.aws/credentials

# now set assumer user to be the default user
echo [default] > ~/.aws/credentials
echo aws_access_key_id=$AccessKeyId >> ~/.aws/credentials
echo aws_secret_access_key=$SecretAccessKey >> ~/.aws/credentials
chmod 600 ~/.aws/credentials
# other options are in ~/.aws/config
# like region and output format
# but we don't need to touch this file

# now any aws commands will be run as the assumer user
# everything will fail except 'aws sts assume-role'
echo aws credentials reset to assumer user \'SEDusernameSED\'
echo access to everything but \'aws sts assume-role\' is disabled
