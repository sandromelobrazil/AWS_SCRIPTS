#!/usr/bin/expect -f

# this script demos how to use nested expect
# by calling expect3.sh with expect

set timeout -1

# this works

spawn ./expect3.sh
interact

send_user "\nsecond run\n"

# this hangs because the expect here interferes
# with nested expect_user

spawn ./expect3.sh
expect "expect3.sh finished"
interact
