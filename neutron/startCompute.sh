set -e
apt update
apt upgrade -y

echo "\nrun neutron.sql"
mysql -e "source neutron.sql";

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=admin
export OS_PASSWORD=9zExzZzL
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

echo "\ninstalling compute node"
apt install neutron-linuxbridge-agent

echo "\nrestart compute service"
service nova-compute restart

echo "\nrestart linux bridge agent"
service neutron-linuxbridge-agent restart