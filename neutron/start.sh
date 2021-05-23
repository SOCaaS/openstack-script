set -e

apt update


echo -e "\n Create a neutron sql user"
sed -i -e "s|{{ NEUTRON_DB_NAME }}|$NEUTRON_DB_NAME|g" ./neutron.sql
sed -i -e "s|{{ NEUTRON_DB_USER }}|$NEUTRON_DB_USER|g" ./neutron.sql
sed -i -e "s|{{ NEUTRON_DB_PASSWORD }}|$NEUTRON_DB_PASSWORD|g" ./neutron.sql

mysql -e "source neutron.sql";

# Export environment variable


echo -e "\nInstalling controller node"
echo -e "\nCreating user and giving admin role"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$NEUTRON_PASSWORD" $NEUTRON_USER
openstack role add --project service --user $NEUTRON_USER admin

echo -e "\nCreate neutron service entity"
openstack service create --name $NEUTRON_USER --description "OpenStack Networking" network

echo -e "\ncreating network service API endpoints"
openstack endpoint create --region RegionOne network public http://$DEFAULT_URL:9696
openstack endpoint create --region RegionOne network internal http://$DEFAULT_URL:9696
openstack endpoint create --region RegionOne network admin http://$DEFAULT_URL:9696

echo -e "\nInstalling networking option1"
apt install -y neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-l3-agent

echo -e "\nEditting neutron.conf"
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://$NEUTRON_DB_USER:$NEUTRON_DB_PASSWORD@$DEFAULT_URL/$NEUTRON_DB_NAME

crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.ml2.plugin.Ml2Plugin
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://$rabbitMQ_USER:$rabbitMQ_PASSWORD@$DEFAULT_URL:5672
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips true

crudini --set /etc/neutron/neutron.conf api auth_strategy keystone

crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://$DEFAULT_URL:5000/
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$DEFAULT_URL:5000/
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers $DEFAULT_URL:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username $NEUTRON_USER
crudini --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASSWORD

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

crudini --set /etc/neutron/neutron.conf nova auth_url http://$DEFAULT_URL:5000/
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/neutron/neutron.conf nova user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username $NOVA_USER
crudini --set /etc/neutron/neutron.conf nova password $NOVA_PASSWORD
crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

echo -e "\nEdit ml2_conf.ini"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
# ,vbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset true

echo -e "\nEdit linuxbridge_agent.ini"
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth0
# ,vbridge:virbr0
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $HOST_IP
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

echo -e "\nConfigure the Layer-3 Agent"
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver linuxbridge

echo -e "\nEdit dhcp_agent.ini"
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver linuxbridge
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true

echo -e "\nEdit editing metadata_agent.ini.conf"
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host $DEFAULT_URL
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $METADATA_PROXY_SHARED_SECRET

echo -e "\nEditing nova.conf"
crudini --set /etc/nova/nova.conf neutron url http://$DEFAULT_URL:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://$DEFAULT_URL:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf neutron user_domain_name $OS_USER_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username $NEUTRON_USER
crudini --set /etc/nova/nova.conf neutron password $NEUTRON_PASSWORD
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy true
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $METADATA_PROXY_SHARED_SECRET

echo -e "\nFinalize installation neutron"
echo -e "\nPopulate database neutron"
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

echo -e "\nRestart compute API service"
service nova-api restart

echo -e "\nRestart networking services"
service neutron-server restart
# service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

echo -e "\nRestart compute service"
service nova-compute restart

#This is to rediscover host
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

echo -e "\nRestart linux bridge agent"
# service neutron-linuxbridge-agent restart

echo -e "\nCheck Neutron Installation"
openstack network agent list
