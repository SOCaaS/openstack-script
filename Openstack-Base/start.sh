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
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | sudo tee /etc/apt/sources.list.d/rabbitmq.list

apt install -y erlang
echo "install rabbitMQ"
#add rabbitmq Repository to Ubuntu
apt install -y apt-transport-https
wget -O- https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | sudo apt-key add -
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
echo "deb https://dl.bintray.com/rabbitmq-erlang/debian focal erlang-22.x" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
suto apt install -y rabbitmq-server
systemctl status rabbitmq-server.service

rabbitmq-plugins enable rabbitmq_management
sudo ufw allow proto tcp from any to any port 5672,15672

rabbitmqctl add_user admin HELP123
rabbitmqctl set_user_tags admin administrator

