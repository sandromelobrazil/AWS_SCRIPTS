#!/bin/python3
import subprocess
import sys

msg1="Sintaxe correta.:  python3 "
msg2=" all  | elastic |  instance | network "

msg_notfunc="Funcionalidade nao implementada"

'''
if len(sys.argv) != 2:
    print(" ")
    print(msg1 + (str(sys.argv[0]))  + " " + msg2)
    print(" Ex.: python " + (str(sys.argv[0])) + "all ")
    print(" Ex.: python " + (str(sys.argv[0])) + "elastic ")
    print(" Ex.: python " + (str(sys.argv[0])) + "instance ")
    print(" Ex.: python " + (str(sys.argv[0])) + "network ")
    print(" ")
    sys.exit(1)

query = str(sys.argv[1])

print(" ")
print('=' * 50)
print "KEEP WALKING - aguarde que a magica vai comecar"
print('=' * 50)

'''
awscmd1='aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text'

def cmd(_command):
	checkip = subprocess.getoutput(_command)
	print(checkip)

def elastic_ip():
	cmd(awscmd1)
	print(msg_notfunc)

def instance_ip():
	cmd(awscmd1)
	print(msg_notfunc)

def network_ip():
	cmd(awscmd1)

def all_ip():
	elastic_ip
	instance_ip
	network_ip
	print(msg_notfunc)





