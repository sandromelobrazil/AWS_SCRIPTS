#!/bin/python3
import subprocess
import sys

msg1="Sintaxe correta.:  python3 "
msg2="[ all  | elastic |  instance | network ]"
msg3="IMPORTANT: Este script foi desenvolvido em Python 3"
msg4="Iniciando a consulta na AWS"
msg_notfunc="Funcionalidade nao implementada"
msg_error="Opcao errada"

print(str(sys.argv))
print(len(sys.argv))

def func_param():
    print(msg3)

    
if len(sys.argv) != 2:
    print(" ")
    print(msg1 + (str(sys.argv[0]))  + " " + msg2)
    print(" Ex.: " + (str(sys.argv[0])) + " all ")
    print(" Ex.: " + (str(sys.argv[0])) + " elastic ")
    print(" Ex.: " + (str(sys.argv[0])) + " instance ")
    print(" Ex.: " + (str(sys.argv[0])) + " network ")
    print(" ")
    func_param
    sys.exit(1)


print(" ")
print("=" * 50)
print(msg4)
print('=' * 50)

awscmd1='aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text'
myquery = str(sys.argv[1])

def cmd(_command):
    print(_command)
    checkip = subprocess.getoutput(_command)
    print(checkip)
    
def elastic_ip():
    print("OK")
    cmd(awscmd1)
#	print(msg_notfunc)
#print(awscmd1)
#print (myquery)

elastic_ip()

'''
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


def main_ip():
    if myquery == elastic:
        elastic_ip

    elif myquery == instance:
        instance_ip

    elif myquery == network:
        network_ip

    elif myquery == all:
        all_ip

    else:
        print(msg4)

main_ip
'''


