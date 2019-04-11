
DATA=$(date +%d/%m/%Y-%H:%M:%S)
CCOR='\033[0;32m'
NCOR='\033[0m'
OK="[*]"
OK_GREEN=$( echo -e $CCOR $OK $NCOR)
VERSION="v1"
MSG_TITLE="Amazon EC2 Simple Script Inventory IP $VERSION "
func_head()
{
    echo " "
    echo -e "$CCOR    __|  __|_  )"
    echo -e "    _|  (     / $NCOR   $MSG_TITLE" 
    echo -e "$CCOR    ___|\___|___| $NCOR"
    echo " "
}
func_head
