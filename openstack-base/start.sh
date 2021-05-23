set -e

echo -e "\nUpdate and Upgrade"
apt update
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' --force-yes -fuy dist-upgrade

echo -e "\nNameserver to Cloudflare"
sed -i -e "s|nameserver.*|nameserver 1.1.1.1|g" /etc/resolv.conf

echo -e "\nInstall Net-Tools"
apt install -y net-tools

echo -e "\nInstall OpenvSwitch"
apt install -y openvswitch-switch

/usr/share/openvswitch/scripts/ovs-ctl start  --system-id="random"

ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6640:$HOST_IP

echo -e "\nInstall Openstack Client"
snap install openstackclients --classic

echo -e "\nInstalling Mysql"
apt install -y mysql-server

service mysql status

echo -e "\nInstall memcache server"
apt install -y memcached

echo -e "\nEcho to /etc/hosts add DEFAULT_URL"

echo -e "\n$HOST_IP $DEFAULT_URL" >> /etc/hosts

echo -e "\nInstalling RabbitMQ"

echo -e "\nInstalling Erlang"

apt-get install -y wget
wget -O- https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | apt-key add -
echo "deb https://packages.erlang-solutions.com/ubuntu focal contrib" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update

apt install -y erlang

echo -e "\nInstall RabbitMQ"

## Team RabbitMQ's main signing key
sudo apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA"
## Launchpad PPA that provides modern Erlang releases
sudo apt-key adv --keyserver "keyserver.ubuntu.com" --recv-keys "F77F1EDA57EBB1CC"
## PackageCloud RabbitMQ repository
curl -1sLf 'https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey' | sudo apt-key add -

#add rabbitmq Repository to Ubuntu
apt install -y apt-transport-https
echo "deb https://dl.bintray.com/rabbitmq-erlang/debian focal erlang-22.x" | tee /etc/apt/sources.list.d/rabbitmq.list
apt update
apt install -y rabbitmq-server

systemctl status rabbitmq-server.service

rabbitmq-plugins enable rabbitmq_management

# set rabbitmq details
rabbitmqctl add_user $rabbitMQ_USER $rabbitMQ_PASSWORD
rabbitmqctl set_user_tags $rabbitMQ_USER administrator
rabbitmqctl set_permissions -p $rabbitMQ_PATH $rabbitMQ_USER ".*" ".*" ".*"

echo -e "\nInstall Crudini"
apt install -y crudini
