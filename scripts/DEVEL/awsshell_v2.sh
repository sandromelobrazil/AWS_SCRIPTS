#!/bin/bash

REGIONS="sa-east-1 us-east-1 us-west-1 us-west-2"
AWS_ACCOUNTS="greenbrasil greendevelop greenhomolog greenprod"
DATA=$(date +%d/%m/%Y-%H:%M:%S)
CCOR='\033[0;32m'
NCOR='\033[0m'
OK="[*]"
OK_GREEN=$( echo -e $CCOR $OK $NCOR)
VERSION="v1"
MSG_TITLE="Amazon EC2 Simple Script Inventory IP $VERSION "

func_clean()
{
for _ACCOUNT in $(echo $AWS_ACCOUNTS)
  do
    [ -f ${ACCOUNT_NOW}_NESSUS_LIST_IP.txt ] && rm -f ${ACCOUNT_NOW}_NESSUS_LIST_IP.txt
done 
    [ -f ALL_NESSUS_LIST_IP.txt ] && rm -f ALL_NESSUS_LIST_IP.txt
}

func_head()
{
    echo " "
    echo -e "$CCOR    __|  __|_  )"
    echo -e "    _|  (     / $NCOR   $MSG_TITLE" 
    echo -e "$CCOR    ___|\___|___| $NCOR"
    echo " "
}

func_network()
{
    aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Association.PublicIp --output text --region $1 --profile $2
}
           
func_instances()
{
    aws ec2 describe-instances --output text  --region $1 --profile $2 |grep ^ASSOCIATION | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" |sort |uniq 
}

func_elastic()
{
    aws ec2 describe-addresses --filter Name=domain,Values=vpc --output json --region $1 --profile $2 | grep PublicIp  | awk '{ print $2}' | cut -f 2 -d \" | grep ^[0-9] 
}


#greenprod
#greenhomolog
#greendevelop
#greenbrasil

func_listip()
{
    for _IP in $( echo "$*" )
      do
        echo "$_IP" >> "ALL_NESSUS_LIST_IP.txt "
        
        if [ -f greenprod.NESSUS_LIST_IP.txt ] 
            then 
                echo "$_IP" >> "greenprod_NESSUS_LIST_IP.txt "

        elif [ -f greenhomolog.NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "greenhomolog_NESSUS_LIST_IP.txt "


        elif [ -f greendevelop.NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "greendevelop_NESSUS_LIST_IP.txt "


        elif [ -f greenbrasil.NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "greenbrasil_NESSUS_LIST_IP.txt "
        else
                echo "Alguma coisa deu errado" 
                exit 1
        fi

        echo "[+] IP Publico: $_IP"
    done
}





func_geteach_ip()
{
    _PROFILE="$1"
    
    for _REGION in $(echo $REGIONS)
      do
        echo "...::: Network IP -> Region $_REGION by Profile $_PROFILE :::..."
        func_listip $( func_network $_REGION $_PROFILE )
        echo .
    done

    for _REGION in $(echo $REGIONS)
      do
        echo "...::: INSTANCE IP  -> Region $_REGION by Profile $_PROFILE :::..." 
        func_listip $( func_instances $_REGION $_PROFILE )
        echo .
     done

    for _REGION in $(echo $REGIONS)
      do
        echo "...::: ELASTIC IP  -> Region $_REGION by Profile $_PROFILE :::..." 
        func_listip $( func_elastic $_REGION $_PROFILE )
        echo .
     done
}



func_account()
{

    _MSGCOUNT="Coleta de informacoes da conta "
    _ACCOUNT="$1"

    case  $_ACCOUNT in
        greenbrasil)
            _PROFILE="checkip_br" 
            echo "$_MSGCOUNT Greenbrasil"
            echo "Green Brasil"
            : > ${_ACCOUNT}_NESSUS_LIST_IP.txt
            func_geteach_ip "$_PROFILE"
            echo . 
        ;;

        greendevelop)
            _PROFILE="checkip_dv" 
            echo "$_MSGCOUNT Greendevelop"
            echo "Desenvolvimento"
            : > ${_ACCOUNT}_NESSUS_LIST_IP.txt
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        greenhomolog)
            _PROFILE="checkip_hm" 
            echo "$_MSGCOUNT Greenhomolog"
            echo "Homologacao"
            : > ${_ACCOUNT}_NESSUS_LIST_IP.txt
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        greenprod)
            _PROFILE="checkip_pdv" 
            echo "$_MSGCOUNT Greenprod"
            echo "Producao"
            : > ${_ACCOUNT}_NESSUS_LIST_IP.txt
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        *)
            echo "Essa conta nao exite"
        ;;
    esac
}

func_head
func_clean

for _ACCOUNT in $(echo $AWS_ACCOUNTS)
  do
    func_account "$_ACCOUNT"
done 
