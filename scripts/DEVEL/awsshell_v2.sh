
#!/bin/bash

REGIONS="sa-east-1 us-east-1 us-west-1 us-west-2"



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
    echo "...::: Network IP :::..."
    func_listip "$IPNETWORK"
    echo .


    echo "...::: INSTANCE IP :::..." 
    func_listip "$IPINSTANCES"
    echo .


    echo "...::: ELASTIC VPC IPs :::..." 
    func_listip "$IPELASTICVPC"
    echo .
}


func_account()
{

    _MSGCOUNT="Coleta de informacoes da conta "

    case  $_ACCOUNT in
        greenbrasil)
        echo "$_MSGCOUNT Greenbrasil"
        echo"Green Brasil"
        echo . 
        ;;

        greendevelop)
        echo "$_MSGCOUNT Greendevelop"
        echo"Desenvolvimento"
        echo . 

        ;;

        greenhomolog)
        echo "$_MSGCOUNT Greenhomolog"
        echo"Homologacao"
        echo . 

        ;;

        greenprod)
        echo "$_MSGCOUNT Greenprod"
        echo"Producao"
        echo . 

        ;;

    esac

}



