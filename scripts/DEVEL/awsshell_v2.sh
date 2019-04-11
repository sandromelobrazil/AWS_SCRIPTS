
#!/bin/bash

REGIONS="sa-east-1 us-east-1 us-west-1 us-west-2"
AWS_ACCOUNTS="greenbrasil greendevelop greenhomolog greenprod"
#AWS_ACCOUNTS="greendevelop"



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
            func_geteach_ip "$_PROFILE"
            echo . 
        ;;

        greendevelop)
            _PROFILE="checkip_dv" 
            echo "$_MSGCOUNT Greendevelop"
            echo "Desenvolvimento"
            func_geteach_ip "$_PROFILE"
            echo . 

        ;;

        greenhomolog)
            _PROFILE="checkip_hm" 
            echo "$_MSGCOUNT Greenhomolog"
            echo "Homologacao"
            echo . 

        ;;

        greenprod)
            _PROFILE="checkip_pdv" 
            echo "$_MSGCOUNT Greenprod"
            echo "Producao"
            echo . 

        ;;

        *)
            echo "Essa conta nao exite"
        ;;
    esac
}

for _ACCOUNT in $(echo $AWS_ACCOUNTS)
  do
    func_account "$_ACCOUNT"

done 
