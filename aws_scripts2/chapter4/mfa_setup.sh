#!/bin/bash

# interactive script to set up a secure user with mfa
# make a new user 'assumer' who can only execute 'aws sts assume-role'
# make 2 new roles which can only be assumed by this user
# the new adminrole has full admin privileges
# the new connectrole has connect privileges
# also make a virtual mfa device, configure it
# and attach it to the user assumer

# make new user
# we need the user arn for the role policy used in 'aws iam create-role'
echo creating iam user assumer
userarn=$(aws iam create-user --user-name assumer --output text --query 'User.Arn')
echo userarn=$userarn

# let the user cook
# else upcoming 'aws iam create-role' fails
sleep 5

# create a role policy that allows assumption by the user
echo creating assume role policy that can be assumed by $username only
assumerolepolicy="{\"Version\": \"2012-10-17\",\"Statement\": [{\"Sid\": \"\",\"Effect\": \"Allow\",\"Principal\": {\"AWS\": \""
assumerolepolicy+=$userarn
assumerolepolicy+="\"},\"Action\": \"sts:AssumeRole\",\"Condition\": { \"Bool\": { \"aws:MultiFactorAuthPresent\": true } }}]}"
echo assumerolepolicy=$assumerolepolicy

# create the admin role
echo creating admin role with this assume role policy
adminrolearn=$(aws iam create-role --role-name assumer_adminrole --assume-role-policy-document "$assumerolepolicy" --output text --query 'Role.Arn')
echo adminrolearn=$adminrolearn

# create the connect role
echo creating connect role with this assume role policy
connectrolearn=$(aws iam create-role --role-name assumer_connectrole --assume-role-policy-document "$assumerolepolicy" --output text --query 'Role.Arn')
echo connectrolearn=$connectrolearn

# attach an admin role policy to the admin role with admin privileges
rolepolicy="{\"Version\": \"2012-10-17\",\"Statement\": [{\"Effect\": \"Allow\",\"Action\": \"*\",\"Resource\": \"*\"}]}"
echo rolepolicy=$rolepolicy
aws iam put-role-policy --role-name assumer_adminrole --policy-name assumer_adminrole_policy --policy-document "$rolepolicy"

# attach a connect role policy to the connect role with connect privileges
rolepolicy="{\"Version\": \"2012-10-17\",\"Statement\": [{\"Effect\": \"Allow\",\"Action\": [\"ec2:DescribeInstances\", \"ec2:DescribeSecurityGroups\", \"ec2:AuthorizeSecurityGroupIngress\", \"ec2:RevokeSecurityGroupIngress\"],\"Resource\": \"*\"}]}"
echo rolepolicy=$rolepolicy
aws iam put-role-policy --role-name assumer_connectrole --policy-name assumer_connectrole_policy --policy-document "$rolepolicy"

# create the policy for the user
# can only run 'aws sts assume-role ...' for the two roles
userpolicy="{\"Version\": \"2012-10-17\",\"Statement\": ["
userpolicy+="{\"Effect\": \"Allow\",\"Action\": \"sts:AssumeRole\",\"Resource\": \""
userpolicy+=$adminrolearn
userpolicy+="\"},"
userpolicy+="{\"Effect\": \"Allow\",\"Action\": \"sts:AssumeRole\",\"Resource\": \""
userpolicy+=$connectrolearn
userpolicy+="\"}"
userpolicy+="]}"
echo userpolicy=$userpolicy

# attach the policy to the user
echo attaching this policy to assumer
aws iam put-user-policy --user-name assumer --policy-name assumer_policy --policy-document "$userpolicy"

# make an access key for the user
# we need to get 2 values from this returned data but can only call the function once
# so we can't use '--query'
cred=$(aws iam create-access-key --user-name assumer --output text)
bits=($cred)
AccessKeyId=${bits[1]}
SecretAccessKey=${bits[3]}

# request user installs mfa app
echo Install the Google Authenticator App on your mobile device
echo THEN press a key
read -n 1 -s

# make a new mfa device
echo making a new virtual mfa device
mfaserial=$(aws iam create-virtual-mfa-device --virtual-mfa-device-name assumer_mfa_device --outfile mfa.png --bootstrap-method QRCodePNG --output text --query 'VirtualMFADevice.SerialNumber')
echo mfaserial=$mfaserial

# request user scans QR code
# QR code here is a must because AWS uses very long MFA keys
# you will make a mistake if you try to type it by hand...
echo open mfa.png in a image viewing app and scan it
echo THEN press a key
read -n 1 -s

# alternatively, if you are using something like OTP Manager
# which allows copy and paste of the mfa seed
# you could use:
#mfaserial=$(aws iam create-virtual-mfa-device --virtual-mfa-device-name assumer_mfa_device --outfile mfa.txt --bootstrap-method Base32StringSeed --output text --query 'VirtualMFADevice.SerialNumber')
#echo copy and paste the following seed into OTP Manager:
#cat mfa.txt

# get 2 mfa codes
read -p "Enter an MFA code (6 numbers): " mfacode1
read -p "Enter the next MFA code (6 numbers): " mfacode2

# enable the mfa device
aws iam enable-mfa-device --user-name assumer --serial-number $mfaserial --authentication-code-1 $mfacode1 --authentication-code-2 $mfacode2
echo mfa device enabled

# delete the QR code
rm -f mfa.png
# or the txt file
#rm -f mfa.txt
echo MFA Key deleted

echo finished mfa setup

echo now building sign in and sign out scripts

# sign in script
# create safe versions of the strings to be inserted
# ie escape / \ and &
adminrolearnsafe=$(echo $adminrolearn | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
echo adminrolearnsafe=$adminrolearnsafe
connectrolearnsafe=$(echo $connectrolearn | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
echo connectrolearnsafe=$connectrolearnsafe
mfaserialsafe=$(echo $mfaserial | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
echo mfaserialsafe=$mfaserialsafe
sed -e "s/SEDadminrolearnSED/$adminrolearnsafe/g" -e "s/SEDconnectrolearnSED/$connectrolearnsafe/g" -e "s/SEDmfaserialSED/$mfaserialsafe/g" -e "s/SEDusernameSED/assumer/g" mfa_signin_template.sh > output/signin.sh
chmod +x output/signin.sh
echo new signin.sh saved to output/signin.sh

# sign out script
# create safe versions of the strings to be inserted
# ie escape / \ and &
AccessKeyIdsafe=$(echo $AccessKeyId | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
echo AccessKeyIdsafe=$AccessKeyIdsafe
SecretAccessKeysafe=$(echo $SecretAccessKey | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
echo SecretAccessKeysafe=$SecretAccessKeysafe
sed -e "s/SEDAccessKeyIdSED/$AccessKeyIdsafe/g" -e "s/SEDSecretAccessKeySED/$SecretAccessKeysafe/g" -e "s/SEDusernameSED/assumer/g" mfa_signout_template.sh > output/signout.sh
chmod +x output/signout.sh
echo new signout.sh saved to output/signout.sh

echo finished mfa setup
echo use \'signout.sh\' to sign out of your current AWS CLI account and enable the assumer user
echo use \'signin.sh admin\' or \'signin.sh connect\' to assume privileges for 1 hour
