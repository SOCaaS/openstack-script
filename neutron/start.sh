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
openstack user create --domain Default --password "tewqewv" neutron
openstack role add --project service --user neutron admin

echo "\nCreate neutron service entity"
openstack service create --name neutron --description "OpenStack Networking" network

echo "\ncreating network service API endpoints"
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

echo "\nInstalling networking option1"
apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent

echo "\neditting neutron.conf"
sed -i -e "s|^connection = .*|connection = mysql+pymysql://neutron:tewqewv@controller/neutron|g" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "core_plugin = m12" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "service_plugin = " /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "transport_url = rabbit://openstack:r32uhdejnkaskj@controller" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "auth_strategy = keystone" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "www_authenticate_uri = http://controller:5000" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_url = http://controller:5000" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "memcached_servers = controller:11211" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_type = password" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "user_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_name = service" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "username = neutron" /etc/neutron/neutron.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "password = tewqewv" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "notify_nova_on_port_status_changes = true" /etc/neutron/neutron.conf
sed -i -e '/^\[DEFAULT\]/a\' -e "notify_nova_on_port_data_changes = true" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "auth_url = http://controller:5000" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "auth_type = password" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "project_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "user_domain_name = default" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "region_name = RegionOne" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "project_name = service" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "username = nova" /etc/neutron/neutron.conf
sed -i -e '/^\[nova\]/a\' -e "password = v3hx4vBB" /etc/neutron/neutron.conf
sed -i -e '/^\[oslo_concurrency\]/a\' -e "lock_path = /var/lib/neutron/tmp" /etc/neutron/neutron.conf

echo "\nml2_conf.ini"
sed -i -e '/^\[ml2\]/a\' -e "type_drivers = flat,vlan" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -e '/^\[ml2\]/a\' -e "tenant_network_types = " /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -e '/^\[ml2\]/a\' -e "mechanism_drivers = linuxbridge" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -e '/^\[ml2\]/a\' -e "extension_drivers = port_security" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -e '/^\[ml2_type_flat\]/a\' -e "flat_networks = provider" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -e '/^\[securitygroup\]/a\' -e "enable_ipset = true" /etc/neutron/plugins/ml2/ml2_conf.ini

echo "\nlinuxbridge_agent.ini"
sed -i -e '/^\[linux_bridge\]/a\' -e "physical_interface_mappings = provider:eth0" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i -e '/^\[vxlan\]/a\' -e "enable_vxlan = false" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i -e '/^\[securitygroup\]/a\' -e "enable_security_group = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i -e '/^\[securitygroup\]/a\' -e "firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

echo "\ndhcp_agent.ini"
sed -i -e '/^\[DEFAULT\]/a\' -e "interface_driver = linuxbridge" /etc/neutron/dhcp_agent.ini
sed -i -e '/^\[DEFAULT\]/a\' -e "dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq" /etc/neutron/dhcp_agent.ini
sed -i -e '/^\[DEFAULT\]/a\' -e "enable_isolated_metadata = true" /etc/neutron/dhcp_agent.ini

echo "\nediting metadata_agent.ini.conf"
sed -i -e '/^\[DEFAULT\]/a\' -e "nova_metadata_host = controller" /etc/neutron/metadata_agent.ini
sed -i -e '/^\[DEFAULT\]/a\' -e "metadata_proxy_shared_secret = wsx32g" /etc/neutron/metadata_agent.ini

echo "\nediting nova.conf"
sed -i -e '/^\[neutron\]/a\' -e "auth_url = http://controller:5000" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "auth_type = password" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_domain_name = Default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "user_domain_name = Default" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "region_name = RegionOne" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "project_name = service" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "username = neutron" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "password = tewqewv" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "service_metadata_proxy = true" /etc/nova/nova.conf
sed -i -e '/^\[neutron\]/a\' -e "metadata_proxy_shared_secret = wsx32g" /etc/nova/nova.conf

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

echo "\ninstalling compute node"
apt install neutron-linuxbridge-agent

echo "\nrestart compute service"
service nova-compute restart

echo "\nrestart linux bridge agent"
service neutron-linuxbridge-agent restart
