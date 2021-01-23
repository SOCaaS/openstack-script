set -e
apt update
apt upgrade -y

echo "Install Net-Tools"
apt install -y net-tools

echo "Install Openstack Client"
snap install openstackclients --classic

echo "Installing Mysql"
apt install -y mysql-server

service mysql status

echo "Install memcache server"
apt install -y memcached

echo -e "\nEcho to /etc/hosts add controller"

echo -e "\n127.0.0.1 controller" >> /etc/hosts

echo "installing rabbitMQ"

echo "installing erlang"
apt-get install -y wget
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update

apt install -y erlang
echo "install rabbitMQ"
#add rabbitmq Repository to Ubuntu
apt install -y apt-transport-https
wget -O- https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | apt-key add -
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -
echo "deb https://dl.bintray.com/rabbitmq-erlang/debian focal erlang-22.x" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update
apt install -y rabbitmq-server
systemctl status rabbitmq-server.service

rabbitmq-plugins enable rabbitmq_management

rabbitmqctl add_user admin r32uhdejnkaskj
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
