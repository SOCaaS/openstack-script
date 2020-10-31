set -e
apt update
apt upgrade -y

echo "Install Net-Tools"
apt install -y net-tools

echo "Install Openstack Client"
snap install openstackclients --classic

echo "Install memcache server"
apt install -y memcached
