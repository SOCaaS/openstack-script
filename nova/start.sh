set -e
apt update
apt upgrade -y

echo -e "\n Create a nova sql user"
sed -i -e "s|{{ NOVA_API_DB_NAME }}|$(grep NOVA_API_DB_NAME ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ NOVA_CELL0_DB_NAME }}|$(grep NOVA_CELL0_DB_NAME ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ NOVA_DB_NAME }}|$(grep NOVA_DB_NAME ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ NOVA_DB_USER }}|$(grep NOVA_DB_USER ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ NOVA_DB_PASSWORD }}|$(grep NOVA_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./placement.sql

mysql -e "source nova.sql";


# export variables
echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

echo "creating openstack user 'nova'"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$(grep NOVA_PASSWORD ../.env | cut -d '=' -f2)" $(grep NOVA_USER ../.env | cut -d '=' -f2)
openstack role add --project service --user $(grep NOVA_USER ../.env | cut -d '=' -f2) admin

openstack service create --name $(grep NOVA_USER ../.env | cut -d '=' -f2) --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8774/v2.1

echo "install nova API"
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler
apt install -y nova-compute

echo "editting nova.conf"

#change api_db and db credential
crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://$(grep NOVA_DB_USER ../.env | cut -d '=' -f2):$(grep NOVA_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep NOVA_API_DB_NAME ../.env | cut -d '=' -f2)
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://$(grep NOVA_DB_USER ../.env | cut -d '=' -f2):$(grep NOVA_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep NOVA_DB_NAME ../.env | cut -d '=' -f2)

#change rabit mq message
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://$(grep rabbitMQ_USER ../.env | cut -d '=' -f2):$(grep rabbitMQ_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5672 

#change api and keystone auth token
crudini --set /etc/nova/nova.conf api auth_strategy keystone 


crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/ 
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/ 
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers $(grep DEFAULT_URL ../.env | cut -d '=' -f2):11211 
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type=password 
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service 
crudini --set /etc/nova/nova.conf keystone_authtoken username $(grep NOVA_USER ../.env | cut -d '=' -f2) 
crudini --set /etc/nova/nova.conf keystone_authtoken password $(grep NOVA_USER ../.env | cut -d '=' -f2)
#change ip
crudini --set /etc/nova/nova.conf DEFAULT my_ip $(grep HOST_IP ../.env | cut -d '=' -f2)
#vnc
crudini --set /etc/nova/nova.conf vnc enabled true 
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address $(grep HOST_IP ../.env | cut -d '=' -f2)
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://$(grep HOST_IP ../.env | cut -d '=' -f2):6080/vnc_auto.html 

#glance
crudini --set /etc/nova/nova.conf glance api_servers http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9292 

#oslo_concurrency
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path=/var/lib/nova/tmp 

#placement pass
crudini --set /etc/nova/nova.conf placement region_name RegionOne 
crudini --set /etc/nova/nova.conf placement project_domain_name $OS_PROJECT_DOMAIN_NAME  
crudini --set /etc/nova/nova.conf placement project_name service 
crudini --set /etc/nova/nova.conf placement auth_type password 
crudini --set /etc/nova/nova.conf placement user_domain_name $OS_USER_DOMAIN_NAME 
crudini --set /etc/nova/nova.conf placement auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/v3 
crudini --set /etc/nova/nova.conf placement username $(grep PLACEMENT_USER ../.env | cut -d '=' -f2) 
crudini --set /etc/nova/nova.conf placement password $(grep PLACEMENT_PASSWORD ../.env | cut -d '=' -f2)

crudini --del /etc/nova/nova.conf DEFAULT log_dir

echo "populate nova-api database"

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

echo "finalize installation"

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

crudini --set /etc/nova/nova-compute.conf libvirt virt_type kvm

service nova-compute restart

openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

crudini --set /etc/nova/nova-compute.conf scheduler discover_hosts_in_cells_interval 300' /etc/nova/nova-compute.conf
