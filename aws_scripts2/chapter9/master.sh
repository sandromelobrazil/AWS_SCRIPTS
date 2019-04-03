#!/bin/bash

# this is the chapter 9 master script
# it builds a bastion (from chapter 8 scripts)
# then 2 internal servers
# next, it configures the 2 internal servers
# next, it updates the 2 internal servers
# next, it updates the 2 internal servers more substantially

# this script needs to be called from chapter9 directory

echo $'\n\n*****\n CHAPTER 9 MASTER SCRIPT\n*****\n\n'

# build a bastion
cd bastion
echo $'\n\n*****\n BUILDING BASTION\n*****\n\n'
./make.sh
echo $'\n\n*****\n BUILT BASTION\n*****\n\n'
cd ..

# build internal servers
cd internal
echo $'\n\n*****\n BUILDING INTERNAL1\n*****\n\n'
./make.sh internal1 10.0.0.11
echo $'\n\n*****\n BUILT INTERNAL1\n*****\n\n'
echo $'\n\n*****\n BUILDING INTERNAL2\n*****\n\n'
./make.sh internal2 10.0.0.12
echo $'\n\n*****\n BUILT INTERNAL2\n*****\n\n'
cd ..

# configure internal servers
cd configure
echo $'\n\n*****\n CONFIGURING\n*****\n\n'
./configure.sh
echo $'\n\n*****\n CONFIGURED\n*****\n\n'
cd ..

echo Sort out Internal2 MFA Code
echo THEN press a key
read -n 1 -s

# update internal servers
cd update
echo $'\n\n*****\n UPDATING\n*****\n\n'
./update.sh
echo $'\n\n*****\n UPDATED\n*****\n\n'
cd ..

# update internal servers more substantially
cd update2
echo $'\n\n*****\n UPDATING PART 2\n*****\n\n'
./update.sh
echo $'\n\n*****\n UPDATED PART 2\n*****\n\n'
cd ..

echo $'\n\n*****\n CHAPTER 9 MASTER SCRIPT FINISHED\n*****\n\n'
