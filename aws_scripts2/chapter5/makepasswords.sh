#!/bin/bash

# generates a file passwords.sh with all passwords

# password for ssher
ssherpassword=$(openssl rand -hex 8)

# password for root
rootpassword=$(openssl rand -hex 8)

# mysql root password
mysql_rootpassword=$(openssl rand -hex 8)

# db
db_webpass=$(openssl rand -hex 8)

# make the AES key (64 characters) for PHP sessions
aes=$(openssl rand -hex 32)

# write file
echo "#!/bin/bash" > passwords.sh
echo "ssherpassword=$ssherpassword" >> passwords.sh
echo "rootpassword=$rootpassword" >> passwords.sh
echo "mysql_rootpassword=$mysql_rootpassword" >> passwords.sh
echo "db_webpass=$db_webpass" >> passwords.sh
echo "aes=$aes" >> passwords.sh
chmod +x passwords.sh
