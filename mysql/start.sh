apt update
apt upgrade -y 

#This install mysql server
echo "Installing Mysql"
apt install -y mysql-server

service mysql status