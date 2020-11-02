set -e
apt update
apt upgrade -y

echo "\nrun neutron.sql"
mysql -e "source neutron.sql";

# Export environment variable
echo -e "\n\nExport environment variable"
export OS_USERNAME=admin
export OS_PASSWORD=9zExzZzL
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

echo "\ninstalling controller node"
echo "\ncreating user and giving admin role"
openstack user create --domain default --password "tewqewv" neutron
openstack role add --project service --user neutron admin

echo "\nCreate neutron service entity"
openstack service create --name neutron --description "OpenStack Networking" network

echo "\ncreating network service API endpoints"
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

echo "\nediting metadata_agent.ini.conf"
sed -i -e '/^\[DEFAULT\]/a\' -e "nova_metadata_host = controller" /etc/neutron/metadata_agent.ini
sed -i -e '/^\[DEFAULT\]/a\' -e "metadata_proxy_shared_secret = METADATA_SECRET" /etc/neutron/metadata_agent.ini

echo "\nediting nova.conf"
sed -i -e '/^\[neutron\]/a\' -e "auth_url = http://controller:5000" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "auth_type = password" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_domain_name = default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "user_domain_name = default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "region_name = RegionOne" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_name = service" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "username = neutron" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "password = tewqewv" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "service_metadata_proxy = true" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "metadata_proxy_shared_secret = METADATA_SECRET" /etc/nova/nova.conf

echo "\nfinalize installation"
echo "\npopulate database"
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

echo "\nrestart compute API service"
service nova-api restart

echo "\nrsetart networking services"
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

echo "\nrestart layer-3 service"
service neutron-l3-agent restart

