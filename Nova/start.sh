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
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler
apt install -y nova-compute

echo "editting nova.conf"
#commenting connection
sed -i -e "s|^connection = .*|#connection = .*|g" /etc/nova/nova.conf

#change api_db and db credential
sed -i -e '/^\[api_database\]/a\' -e 'connection = mysql+pymysql://nova:anq9SXHR@controller/nova_api' /etc/nova/nova.conf
sed -i -e '/^\[database\]/a\' -e 'connection = mysql+pymysql://nova:anq9SXHR@controller/nova' /etc/nova/nova.conf

#change rabit mq message
sed -i -e '/^\[DEFAULT\]/a\' -e 'transport_url = rabbit://openstack:r32uhdejnkaskj@controller:5672' /etc/nova/nova.conf

#change api and keystone auth token
sed -i -e '/^\[api\]/a\' -e 'auth_strategy = keystone' /etc/nova/nova.conf


sed -i -e '/^\[keystone_authtoken\]/a\' -e 'www_authenticate_uri = http://controller:5000/' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'auth_url = http://controller:5000/' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'memcached_servers = controller:11211' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'auth_type=password' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'project_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'user_domain_name = Default' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'project_name = service' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'username = nova' /etc/nova/nova.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e 'password = v3hx4vBB' /etc/nova/nova.conf
#change ip
sed -i -e '/^\[DEFAULT\]/a\' -e 'my_ip = 10.0.0.11' /etc/nova/nova.conf
#vnc
sed -i -e '/^\[vnc\]/a\' -e 'enabled = true' /etc/nova/nova.conf
sed -i -e '/^\[vnc\]/a\' -e 'server_listen = $my_ip' /etc/nova/nova.conf
sed -i -e '/^\[vnc\]/a\' -e 'server_proxyclient_address = $my_ip' /etc/nova/nova.conf
sed -i -e '/^\[vnc\]/a\' -e 'novncproxy_base_url = http://controller:6080/vnc_auto.html' /etc/nova/nova.conf

#glance
sed -i -e '/^\[glance\]/a\' -e 'api_servers = http://controller:9292' /etc/nova/nova.conf

#oslo_concurrency
sed -i -e '/^\[oslo_concurrency\]/a\' -e 'lock_path=/var/lib/nova/tmp' /etc/nova/nova.conf
sed -i '/log_dir/d' /etc/nova/nova.conf

#placement pass
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
egrep -c '(vmx|svm)' /proc/cpuinfo
sed -i -e '/^\[libvirt\]/a\' -e 'virt_type = qemu' /etc/nova/nova-compute.conf

service nova-compute restart

openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

sed -i -e '/^\[scheduler\]/a\' -e 'discover_hosts_in_cells_interval = 300' /etc/nova/nova-compute.conf
