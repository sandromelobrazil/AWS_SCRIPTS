#!/bin/bash


REGIONS="ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1 us-east-2 us-west-1 us-west-2 uss-east-1"
#REGIONS="ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 cn-north-1 cn-northwest-1 eu-central-1 eu-north-1 eu-west-1 eu-west-2 eu-west-3 sa-east-1 us-east-2 us-gov-east-1 us-gov-west-1 us-west-1 us-west-2 uss-east-1"
#REGIONS="sa-east-1 us-east-1 us-west-1 us-west-2"

AWS_ACCOUNTS="conta_aws_brasil conta_aws_develop conta_aws_homolog conta_aws_prod"
DATA=$(date +%d/%m/%Y-%H:%M:%S)
CCOR='\033[0;32m'
NCOR='\033[0m'
OK="[*]"
OK_RED=$( echo -e $CCOR $OK $NCOR)
VERSION="v1"
MSG_TITLE="Amazon EC2 Simple Script Inventory IP $VERSION "

func_clean()
{
for _ACCOUNT in $(echo $AWS_ACCOUNTS)
  do
    [ -f ${_ACCOUNT}_NESSUS_LIST_IP.txt ] && rm -f ${_ACCOUNT}_NESSUS_LIST_IP.txt
done 
    [ -f ALL_NESSUS_LIST_IP.txt ] && rm -f ALL_NESSUS_LIST_IP.txt
    [ -f ${0}___.log ] && rm -f ${0}___.log 
}

func_head()
{
    echo " "
    echo -e "$CCOR    __|  __|_  )"
    echo -e "    _|  (     / $NCOR   $MSG_TITLE" 
    echo -e "$CCOR    ___|\___|___| $NCOR"
    echo -e "Acessando a conta ... "
    echo -e "          SOMOSPI --> $CCOR $1 $NCOR"
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

func_listip()
{
    for _IP in $( echo "$*" )
      do
        echo "$_IP" >> "ALL_NESSUS_LIST_IP.txt"
        
        if [ -f conta_aws_prod_NESSUS_LIST_IP.txt ] 
            then 
                echo "$_IP" >> "conta_aws_prod_NESSUS_LIST_IP.txt"

        elif [ -f conta_aws_homolog_NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "conta_aws_homolog_NESSUS_LIST_IP.txt"

        elif [ -f conta_aws_develop_NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "conta_aws_develop_NESSUS_LIST_IP.txt"

        elif [ -f conta_aws_brasil_NESSUS_LIST_IP.txt ] 
            then
                echo "$_IP" >> "conta_aws_brasil_NESSUS_LIST_IP.txt"
        else
                echo "Alguma coisa deu errado" 
                exit 1
        fi

        echo "$OK_RED IP Publico: $_IP"
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
        conta_aws_brasil)
            func_head "RED BRASIL - conta_aws_brazil"
            _PROFILE="checkip_br" 
            echo "$_MSGCOUNT Redbrasil"
            echo "Red Brasil"
            : > "${_ACCOUNT}_NESSUS_LIST_IP.txt"
            func_geteach_ip "$_PROFILE"
            echo . 
        ;;

        conta_aws_develop)
            func_head "RED DESENVOLVIMENTO - conta_aws_develop"
            _PROFILE="checkip_dv" 
            echo "$_MSGCOUNT Reddevelop"
            echo "Desenvolvimento"
            : > "${_ACCOUNT}_NESSUS_LIST_IP.txt"
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        conta_aws_homolog)
            func_head "RED HOMOLOGACAO - conta_aws_develop"
            _PROFILE="checkip_hm" 
            echo "$_MSGCOUNT Redhomolog"
            echo "Homologacao"
            : > "${_ACCOUNT}_NESSUS_LIST_IP.txt"
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        conta_aws_prod)
            func_head "RED PRODUCAO - conta_aws_prod"
            _PROFILE="checkip_pd" 
            echo "$_MSGCOUNT Redprod"
            echo "Producao"
             : > "${_ACCOUNT}_NESSUS_LIST_IP.txt"
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        *)
            echo "Essa conta nao exite"
        ;;
    esac
}

func_clean

or _ACCOUNT in $(echo $AWS_ACCOUNTS)
  do
    func_account "$_ACCOUNT"
done | tee ${0}___.log  
