#!/bin/bash

# this script is run on the bastion with expect
# it lists all folders beginning with 'internal'
# then runs make.sh from each folder
# would work for any number of folders

# squid already installed
sudo service squid start

# install expect (it's needed by the make.sh scripts that follow)
sudo yum -y install expect

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

# remove expect
sudo yum -y erase expect

# cleanup
cd ~
rm -f -r *

echo finished install.sh on bastion

# exits from ssh
# because this script was called with '. ./install.sh'
exit
