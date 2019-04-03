#!/bin/bash

# this script is run on the bastion with expect
# it starts squid
# it lists all folders beginning with 'internal'
# then runs make.sh from each folder
# would work for any number of folders

# start squid
sudo service squid start

# make vars.sh executable just in case
chmod +x vars.sh

# list internal* folders and loop
folders=$(ls -d internal*)
bits=($folders)
for i in "${bits[@]}"
do
 echo running $i/make.sh
 cd $i
 chmod +x make.sh
 ./make.sh
 cd ..
 echo finished $i/make.sh
done

# stop squid
sudo service squid stop

echo finished install.sh on bastion
