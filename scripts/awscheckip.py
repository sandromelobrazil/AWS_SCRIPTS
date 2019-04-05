#!/bin/python3
import subprocess
import sys
import socket
import re

msg1="Sintaxe correta.:  python3 "
msg2="[ all  | elastic |  instance | network ]"
msg3="IMPORTANT: Este script foi desenvolvido em Python 3"
msg4="Iniciando a consulta na AWS"
msg_notfunc="Funcionalidade nao implementada"
msg_error="Opcao errada"


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

def func_msgstart():
    print(" ")
    print("=" * 50)
    print(msg4)
    print('=' * 50)

awscmd1='aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text'
awscmd2='aws ec2 describe-instances --output text'
#|grep ^ASSOCIATION | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"'
#|sort |uniq

#regexips = re.findall(r'[0-9]+(?:\.[0-9]+){3}', ip)'
# for _ip in regexips:
#    newip.append(_ip)

myquery = str(sys.argv[1])
'''
def cmd(_command):
    func_msgstart()
    checkip = subprocess.getoutput(_command)
    print(checkip)
'''

def cmd(_command):
    func_msgstart()
    check_ip = subprocess.getoutput(_command)
    print("####")
    print(type(check_ip))
    
    _break = 0
    while _break < 1:
        print(check_ip)
        _break += 1
    
def elastic_ip():
    cmd(awscmd2)

def instance_ip():
	print(msg_notfunc)
	#cmd(awscmd1)

def network_ip():
	cmd(awscmd1)

def all_ip():
	elastic_ip()
	instance_ip()
	network_ip()
	print(msg_notfunc)
    
def main_ip():
    print(myquery)
    if myquery == "elastic":
        elastic_ip()

    elif myquery == "instance":
        instance_ip()

    elif myquery == "network":
        network_ip()

    elif myquery == "all":
        all_ip()

    else:
        print(msg_error)

main_ip()
