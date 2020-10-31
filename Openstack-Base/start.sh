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
