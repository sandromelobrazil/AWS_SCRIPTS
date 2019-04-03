#!/usr/bin/expect -f

# this script demos how to use expect
# to get user input and print it

set timeout -1
send_user "code: "
expect_user -re "(.*)\n"
send_user "you typed code: $expect_out(1,string)\n"
