
DATA=$(date +%d/%m/%Y-%H:%M:%S)
CCOR='\033[0;32m'
NCOR='\033[0m'
OK="[*]"
OK_GREEN="$CCOR $OK $NCOR"

func_head()
{
    echo .
    echo -e "$CCOR __|  __|_  )"
    echo -e " _|  (     / $NCOR   Amazon EC2 Simple Script Inventory IP" 
    echo -e "$CCOR ___|\___|___| $NCOR"
}
func_head
