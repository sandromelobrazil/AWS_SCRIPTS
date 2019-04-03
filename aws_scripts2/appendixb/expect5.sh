#!/usr/bin/expect -f

# this script demos how to use 'read' in subscripts
# by calling expect6.sh with expect

set timeout -1

# this works

spawn ./expect6.sh
interact

send_user "\nsecond run\n"

# this hangs because the expect here interferes
# with nested read

spawn ./expect6.sh
expect "done connecting"
interact
