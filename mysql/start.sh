apt update
apt upgrade

#This install mysql server
echo "Installing Mysql"
apt install -y mysql-server

service mysql status