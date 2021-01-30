set -e
apt update


echo -e "\n Create a CINDER sql user"
sed -i -e "s|{{ CINDER_DB_NAME }}|$(grep CINDER_DB_NAME ../.env | cut -d '=' -f2)|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_USER }}|$(grep CINDER_DB_USER ../.env | cut -d '=' -f2)|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_PASSWORD }}|$(grep CINDER_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./cinder.sql

mysql -e "source cinder.sql";

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

echo -e "\nInstalling controller node"
echo -e "\nCreating user and giving admin role"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password $(grep CINDER_PASSWORD ../.env | cut -d '=' -f2) $(grep CINDER_USER ../.env | cut -d '=' -f2)
openstack role add --project service --user $(grep CINDER_USER ../.env | cut -d '=' -f2) admin

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
crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://$(grep CINDER_DB_USER ../.env | cut -d '=' -f2):$(grep CINDER_DB_PASSWORD ../.env | cut -d '=' -f2)@$DEFAULT_URL/$(grep CINDER_DB_NAME ../.env | cut -d '=' -f2)
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
crudini --set /etc/cinder/cinder.conf keystone_authtoken username $(grep CINDER_USER ../.env | cut -d '=' -f2)
crudini --set /etc/cinder/cinder.conf keystone_authtoken password $(grep CINDER_PASSWORD ../.env | cut -d '=' -f2)

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





