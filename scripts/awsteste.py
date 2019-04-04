#!/bin/python3
import subprocess

import sys

MSG1="Sintaxe correta.:  python3 "
MSG2=" ALL  | ELASTIC |  INSTANCE | NETWORK "
'''
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

'''
awscmd1='aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text'

def cmd(command):
   # result = Result()

    p = Popen(shlex.split(command), stdin=PIPE, stdout=PIPE, stderr=PIPE)
    (stdout, stderr) = p.communicate()

    result.exit_code = p.returncode
    result.stdout = stdout
    result.stderr = stderr
    result.command = command

    if p.returncode != 0:
        print('Error executing command [%s]' % command)
        print('stderr: [%s]' % stderr)
        print('stdout: [%s]' % stdout)

  ##  return result 

cmd(awscmd1)


