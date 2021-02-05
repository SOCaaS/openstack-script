set -e
apt update


echo -e "\n Create a nova sql user"
sed -i -e "s|{{ NOVA_API_DB_NAME }}|$NOVA_API_DB_NAME|g" ./nova.sql
sed -i -e "s|{{ NOVA_CELL0_DB_NAME }}|$NOVA_CELL0_DB_NAME|g" ./nova.sql
sed -i -e "s|{{ NOVA_DB_NAME }}|$NOVA_DB_NAME|g" ./nova.sql
sed -i -e "s|{{ NOVA_DB_USER }}|$NOVA_DB_USER|g" ./nova.sql
sed -i -e "s|{{ NOVA_DB_PASSWORD }}|$NOVA_DB_PASSWORD|g" ./nova.sql

mysql -e "source nova.sql";

echo -e "\nCreating openstack user 'nova'"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$NOVA_PASSWORD" $NOVA_USER
openstack role add --project service --user $NOVA_USER admin

openstack service create --name $NOVA_USER --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://$DEFAULT_URL:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$DEFAULT_URL:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$DEFAULT_URL:8774/v2.1

echo -e "\nInstall nova API"
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler
apt install -y nova-compute

echo -e "\nEditting nova.conf"

#change api_db and db credential
crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://$NOVA_DB_USER:$NOVA_DB_PASSWORD@$DEFAULT_URL/$NOVA_API_DB_NAME
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://$NOVA_DB_USER:$NOVA_DB_PASSWORD@$DEFAULT_URL/$NOVA_DB_NAME

#change rabit mq message
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://$rabbitMQ_USER:$rabbitMQ_PASSWORD@$DEFAULT_URL:5672 

#change api and keystone auth token
crudini --set /etc/nova/nova.conf api auth_strategy keystone 


crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://$DEFAULT_URL:5000/ 
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$DEFAULT_URL:5000/ 
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers $DEFAULT_URL:11211 
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password 
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service 
crudini --set /etc/nova/nova.conf keystone_authtoken username $NOVA_USER 
crudini --set /etc/nova/nova.conf keystone_authtoken password $NOVA_PASSWORD
#change ip
crudini --set /etc/nova/nova.conf DEFAULT my_ip $HOST_IP
#vnc
crudini --set /etc/nova/nova.conf vnc enabled true 
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address $DEFAULT_URL
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://$DEFAULT_URL:6080/vnc_auto.html 

#glance
crudini --set /etc/nova/nova.conf glance api_servers http://$DEFAULT_URL:9292 

#oslo_concurrency
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path=/var/lib/nova/tmp 

#placement pass
crudini --set /etc/nova/nova.conf placement region_name RegionOne 
crudini --set /etc/nova/nova.conf placement project_domain_name $OS_PROJECT_DOMAIN_NAME  
crudini --set /etc/nova/nova.conf placement project_name service 
crudini --set /etc/nova/nova.conf placement auth_type password 
crudini --set /etc/nova/nova.conf placement user_domain_name $OS_USER_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf placement auth_url http://$DEFAULT_URL:5000/v3 
crudini --set /etc/nova/nova.conf placement username $PLACEMENT_USER 
crudini --set /etc/nova/nova.conf placement password $PLACEMENT_PASSWORD

crudini --set /etc/nova/nova.conf libvirt inject_password true
crudini --set /etc/nova/nova.conf libvirt inject_key true
crudini --set /etc/nova/nova.conf libvirt inject_partition -1

crudini --del /etc/nova/nova.conf DEFAULT log_dir

echo -e "\nPopulate nova-api database"

su -s /bin/sh -c "nova-manage api_db sync" nova
# su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
# su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
# su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

echo -e "\nFinalize installation"

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

crudini --set /etc/nova/nova-compute.conf libvirt virt_type kvm

service nova-compute restart

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
su -s /bin/sh -c "nova-manage cell_v2 simple_cell_setup" nova

crudini --set /etc/nova/nova-compute.conf scheduler discover_hosts_in_cells_interval 300

echo -e "\nCheck Nova Installation"
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check
