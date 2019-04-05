#!/bin/bash


IPNETWORK=$(aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text)


IPINSTANCES=$( aws ec2 describe-instances --output text |grep ^ASSOCIATION | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" |sort |uniq )

IPELASTICVPC=$( aws ec2 describe-addresses --filter Name=domain,Values=vpc --output json |grep PublicIp | awk '{ print $2}' | cut -f 2 -d \" | grep ^[0-9] )
func_listip()
{
    for _IP in $( echo $1 )
      do
        echo "[+] IP Publico: $_IP"
    done
}

echo "...::: Network IP :::..."
func_listip "$IPNETWORK"
echo .


echo "...::: INSTANCE IP :::..." 
func_listip "$IPINSTANCES"
echo .


echo "...::: ELASTIC VPC IPs :::..." 
func_listip "$IPELASTICVPC"
echo .


