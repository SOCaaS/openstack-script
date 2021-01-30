set -e
apt update
apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade

echo -e "Install Net-Tools"
apt install -y net-tools

echo -e "Install Openstack Client"
snap install openstackclients --classic

echo -e "Installing Mysql"
apt install -y mysql-server

service mysql status

echo -e "Install memcache server"
apt install -y memcached

echo -e "\nEcho to /etc/hosts add DEFAULT_URL"

echo -e "\n$HOST_IP $DEFAULT_URL" >> /etc/hosts

echo -e "Installing RabbitMQ"

echo -e "Installing Erlang"

apt-get install -y wget
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update

apt install -y erlang

echo -e"Install RabbitMQ"
#add rabbitmq Repository to Ubuntu
apt install -y apt-transport-https
wget -O- https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | apt-key add -
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | apt-key add -
echo "deb https://dl.bintray.com/rabbitmq-erlang/debian focal erlang-22.x" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update
apt install -y rabbitmq-server

systemctl status rabbitmq-server.service

rabbitmq-plugins enable rabbitmq_management

# set rabbitmq details
rabbitmqctl add_user $rabbitMQ_USER $rabbitMQ_PASSWORD
rabbitmqctl set_user_tags $rabbitMQ_USER administrator
rabbitmqctl set_permissions -p $rabbitMQ_PATH $rabbitMQ_USER ".*" ".*" ".*"

echo -e "Install Crudini"
apt install -y crudini