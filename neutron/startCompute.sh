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

echo "\nediting neutron.conf"
sed -i -e '/^\[DEFAULT\]/a\' -e "transport_url = rabbit://openstack:RABBIT_PASS@controller" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e 'auth_strategy = keystone' /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_url = http://controller:5000" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "memcached_servers = controller:11211" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_type = password" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "user_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_name = service" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "username = neutron" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "password = tewqewv" /etc/neutron/neutron.conf
sed -i -e '/^\[oslo_concurrency\]/a\' -e "lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf

echo "\nediting nova.conf"
sed -i -e '/^\[neutron\]/a\' -e "auth_url = http://controller:5000" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "auth_type = password" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_domain_name = default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "user_domain_name = default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "region_name = RegionOne" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_name = service" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "username = neutron" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "password = tewqewv" /etc/nova/nova.conf

echo "\nrestart compute service"
service nova-compute restart

echo "\nrestart linux bridge agent"
service neutron-linuxbridge-agent restart