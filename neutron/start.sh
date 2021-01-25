set -e
apt update
apt upgrade -y

echo -e "\n Create a neutron sql user"
sed -i -e "s|{{ NEUTRON_DB_NAME }}|$(grep NEUTRON_DB_NAME ../.env | cut -d '=' -f2)|g" ./neutron.sql
sed -i -e "s|{{ NEUTRON_DB_USER }}|$(grep NEUTRON_DB_USER ../.env | cut -d '=' -f2)|g" ./neutron.sql
sed -i -e "s|{{ NEUTRON_DB_PASSWORD }}|$(grep NEUTRON_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./neutron.sql

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

echo -e "\nInstalling  $(grep DEFAULT_URL ../.env | cut -d '=' -f2) node"
echo -e "\nCreating user and giving admin role"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$(grep NEUTRON_PASSWORD ../.env | cut -d '=' -f2)" $(grep NEUTRON_USER ../.env | cut -d '=' -f2)
openstack role add --project service --user $(grep NEUTRON_USER ../.env | cut -d '=' -f2) admin

echo -e "\nCreate neutron service entity"
openstack service create --name $(grep NEUTRON_USER ../.env | cut -d '=' -f2) --description "OpenStack Networking" network

echo -e "\ncreating network service API endpoints"
openstack endpoint create --region RegionOne network public http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9696
openstack endpoint create --region RegionOne network internal http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9696
openstack endpoint create --region RegionOne network admin http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9696

echo -e "\nInstalling networking option1"
apt install -y neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent

echo -e "\neditting neutron.conf"
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://$(grep NEUTRON_DB_USER ../.env | cut -d '=' -f2):$(grep NEUTRON_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep NEUTRON_DB_NAME ../.env | cut -d '=' -f2)

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin m12
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://$(grep rabbitMQ_USER ../.env | cut -d '=' -f2):$(grep rabbitMQ_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5672
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $(grep DEFAULT_URL ../.env | cut -d '=' -f2):11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username $(grep NEUTRON_USER ../.env | cut -d '=' -f2)
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $(grep NEUTRON_PASSWORD ../.env | cut -d '=' -f2)

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

crudini --set /etc/neutron/neutron.conf nova auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/neutron/neutron.conf nova user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username $(grep NOVA_USER ../.env | cut -d '=' -f2)
crudini --set /etc/neutron/neutron.conf nova password $(grep NOVA_PASSWORD ../.env | cut -d '=' -f2)
crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

echo -e "\nml2_conf.ini"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

echo -e "\nlinuxbridge_agent.ini"
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth0
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan false
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

echo -e "\ndhcp_agent.ini"
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

echo -e "\nediting metadata_agent.ini.conf"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host $(grep DEFAULT_URL ../.env | cut -d '=' -f2)
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $(grep METADATA_PROXY_SHARED_SECRET ../.env | cut -d '=' -f2)

echo "\nediting nova.conf"
crudini --set /etc/nova/nova.conf neutron auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf neutron user_domain_name $OS_USER_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username $(grep NEUTRON_USER ../.env | cut -d '=' -f2)
crudini --set /etc/nova/nova.conf neutron password $(grep NEUTRON_PASSWORD ../.env | cut -d '=' -f2)
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $(grep METADATA_PROXY_SHARED_SECRET ../.env | cut -d '=' -f2)

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

echo "\nrestart compute service"
service nova-compute restart

echo "\nrestart linux bridge agent"
service neutron-linuxbridge-agent restart
