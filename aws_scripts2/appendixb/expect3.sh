#!/bin/bash

# this script demos nested expects
# ex1.sh prompts for a string
# then spawns ex2.sh
# ex2.sh also prompts for a string
# but ex1.sh auto fills it out

echo "#!/usr/bin/expect -f" > ex1.sh
echo "set timeout -1" >> ex1.sh
echo "send_user \"code1: \"" >> ex1.sh
echo "expect_user -re \"(.*)\n\"" >> ex1.sh
echo 'send_user "you typed code1: $expect_out(1,string)\n"' >> ex1.sh
echo "spawn ./ex2.sh" >> ex1.sh
echo "expect \"code2: \"" >> ex1.sh
echo 'send $expect_out(1,string)\n' >> ex1.sh
echo "interact" >> ex1.sh

echo
echo ex1.sh file:
cat ex1.sh
echo

echo "#!/usr/bin/expect -f" > ex2.sh
echo "set timeout -1" >> ex2.sh
echo "send_user \"code2: \"" >> ex2.sh
echo "expect_user -re \"(.*)\n\"" >> ex2.sh
echo 'send_user "ex1.sh typed code2: $expect_out(1,string)\n"' >> ex2.sh

echo
echo ex2.sh file:
cat ex2.sh
echo

chmod +x ex1.sh
chmod +x ex2.sh
./ex1.sh
rm ex1.sh
rm ex2.sh

echo expect3.sh finished
