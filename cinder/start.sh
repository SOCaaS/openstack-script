set -e
apt update


echo -e "\n Create a CINDER sql user"
sed -i -e "s|{{ CINDER_DB_NAME }}|$CINDER_DB_NAME|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_USER }}|$CINDER_DB_USER|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_PASSWORD }}|$CINDER_DB_PASSWORD|g" ./cinder.sql

mysql -e "source cinder.sql";

# Export environment variable


echo -e "\nInstalling controller node"
echo -e "\nCreating user and giving admin role"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password $CINDER_PASSWORD $CINDER_USER
openstack role add --project service --user $CINDER_USER admin

echo -e "\nInstalling Block Storage Node"
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne volumev2 public http://$DEFAULT_URL:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$DEFAULT_URL:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$DEFAULT_URL:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://$DEFAULT_URL:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://$DEFAULT_URL:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://$DEFAULT_URL:8776/v3/%\(project_id\)s

echo -e "\nInstall cinder"
apt install -y cinder-api cinder-scheduler

echo -e "\nConfigure Database and Rabbitmq Access"
crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://$CINDER_DB_USER:$CINDER_DB_PASSWORD@$DEFAULT_URL/$CINDER_DB_NAME
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://$rabbitMQ_USER:$rabbitMQ_PASSWORD@$DEFAULT_URL:5672

echo -e "\nConfigure keystone"
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://$DEFAULT_URL:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://$DEFAULT_URL:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers $DEFAULT_URL:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username $CINDER_USER
crudini --set /etc/cinder/cinder.conf keystone_authtoken password $CINDER_PASSWORD

echo -e "\nSet Default IP"
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip $HOST_IP
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

echo -e "\nDB Sync"
su -s /bin/sh -c "cinder-manage db sync" cinder

crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne

echo -e "\nRestart all service"
service nova-api restart
service cinder-scheduler restart
service apache2 restart

echo -e "\nCheck volume service"
openstack volume service list





