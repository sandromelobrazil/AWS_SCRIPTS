#!/bin/python3
import subprocess

import sys

MSG1="Sintaxe correta.:  python3 "
MSG2=" ALL  | ELASTIC |  INSTANCE | NETWORK "

if len(sys.argv) != 3:
    print(" ")
    print(MSG1 + (str(sys.argv[0]))  + " " + MSG2)
    print(" Ex.: python " + (str(sys.argv[0])) + "ALL ")
    print(" Ex.: python " + (str(sys.argv[0])) + "ELASTIC ")
    print(" Ex.: python " + (str(sys.argv[0])) + "INSTANCE ")
    print(" Ex.: python " + (str(sys.argv[0])) + "NETWORK ")
    print(" ")
    sys.exit(1)

query = str(sys.argv[1])

print(" ")
print('=' * 50)
print "KEEP WALKING - aguarde que a magica vai comecar"
print('=' * 50)


awscmd1='aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text'

subprocess.Popen(awscmd1, shell=True, stdout = subprocess.PIPE)
#push=subprocess.Popen(awscmd1, shell=True, stdout = subprocess.PIPE)
#
#print push.returncode
#print push







