
#!/bin/bash

REGIONS="sa-east-1 us-east-1 us-west-1 us-west-2"
#AWS_ACCOUNTS="greenbrasil greendevelop greenhomolog greenprod"
AWS_ACCOUNTS="greendevelop"


Func_network()
{
    aws ec2 describe-network-interfaces --query \
    NetworkInterfaces[*].Association.PublicIp --output text) --region $1 \
    --profile $2
}
           

IPINSTANCES=$( aws ec2 describe-instances --output text |grep ^ASSOCIATION | grep -oE "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b" |sort |uniq )

IPELASTICVPC=$( aws ec2 describe-addresses --filter Name=domain,Values=vpc --output json |grep PublicIp | awk '{ print $2}' | cut -f 2 -d \" | grep ^[0-9] )

func_listip()
{
    for _IP in $( echo $1 )
      do
        echo "[+] IP Publico: $_IP"
    done
}

func_geteach_ip()
{
    for _REGION in $(echo $REGIONS)
      do
        _PROFILE="$1"
        echo "...::: Network IP :::..."
        func_listip $( Func_network $_REGION $_PROFILE )
        echo .
    done

#    echo "...::: INSTANCE IP :::..." 
#    func_listip "$IPINSTANCES"
#    echo .

#    echo "...::: ELASTIC VPC IPs :::..." 
#    func_listip "$IPELASTICVPC"
#    echo .
}


func_account()
{

    _MSGCOUNT="Coleta de informacoes da conta "
    _ACCOUNT="$1"

    case  $_ACCOUNT in
        greenbrasil)
        _PROFILE="checkip_br" 
        echo "$_MSGCOUNT Greenbrasil"
        echo"Green Brasil"
        func_geteach_ip "$_PROFILE"
        echo . 
        ;;

        greendevelop)
        _PROFILE="checkip_dv" 
        echo "$_MSGCOUNT Greendevelop"
        echo"Desenvolvimento"
        echo . 

        ;;

        greenhomolog)
        _PROFILE="checkip_hm" 
        echo "$_MSGCOUNT Greenhomolog"
        echo"Homologacao"
        echo . 

        ;;

        greenprod)
        _PROFILE="checkip_pdv" 
        echo "$_MSGCOUNT Greenprod"
        echo"Producao"
        echo . 

        ;;

    esac
}

for _ACCOUNT in $(echo AWS_ACCOUNTS)
  do


done 
