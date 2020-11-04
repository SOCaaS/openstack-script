set -e
apt update
apt upgrade -y

echo "run nova.sql"
mysql -e "source nova.sql";

echo "export variables"
export OS_USERNAME=admin
export OS_PASSWORD=9zExzZzL
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

echo "creating openstack user 'nova'"
openstack user create --domain default --password v3hx4vBB nova
openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1

echo "install nova API"
apt install nova-api nova-conductor nova-novncproxy nova-scheduler

echo "editting nova.conf"
sed -i -e '/^\[api_database\]/a\' -e 'connection = mysql+pymysql://nova:anq9SXHR@controller/nova' /etc/nova/nova.conf
sed -i -e '/^\[database\]/a\' -e 'connection = mysql+pymysql://nova:anq9SXHR@controller/nova' /etc/nova/nova.conf

sed -i -e '/^\[DEFAULT\]/a\' -e 'transport_url = rabbit://openstack:HELP123@controller:5672' /etc/nova/nova.conf
sed -i -e '/^\[api\]/a\' -e 'auth_strategy = keystone' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'www_authenticate_uri = http://controller:5000/' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'auth_url = http://controller:5000/' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'memcached_servers = controller:11211' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'auth_type=password' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'project_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'user_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'project_name = service' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'username = nova' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authoken\]/a\' -e 'password = v3hx4vBB' /etc/nova/nova.conf

sed -i -e '/^\[DEFAULT\]/a\' -e 'my_ip = 10.0.0.11' /etc/nova/nova.conf

sed -i -e '/^\[vnc\]/a\' -e 'enabled = true' /etc/nova/nova.conf
sed -i -e '/^\[vnc\]/a\' -e 'server_listen = $my_ip' /etc/nova/nova.conf
sed -i -e '/^\[vnc\]/a\' -e 'server_proxyclient_address = $my_ip' /etc/nova/nova.conf


sed -i -e '/^\[glance\]/a\' -e 'api_servers = http://controller:9292' /etc/nova/nova.conf


sed -i -e '/^\[oslo_concurrency\]/a\' -e 'lock_path=/var/lib/nova/tmp' /etc/nova/nova.conf


sed -i -e '/^\[placement\]/a\' -e 'region_name = RegionOne' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'project_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'project_name = service' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'auth_type = password' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'user_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'auth_url = http://controller:5000/v3' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'username = placement' /etc/nova/nova.conf
sed -i -e '/^\[placement\]/a\' -e 'password = v3hx4vBB' /etc/nova/nova.conf

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

echo "compute node installation"





