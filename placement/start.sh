set -e
apt update


# run placement.sql
echo -e "\n Create a placement sql user"

sed -i -e "s|{{ PLACEMENT_DB_NAME }}|$(grep PLACEMENT_DB_NAME ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ PLACEMENT_DB_USER }}|$(grep PLACEMENT_DB_USER ../.env | cut -d '=' -f2)|g" ./placement.sql
sed -i -e "s|{{ PLACEMENT_DB_PASSWORD }}|$(grep PLACEMENT_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./placement.sql

mysql -e "source placement.sql";

# export variables
echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

# create placement user and give admin role
echo "creating openstack user 'placement'"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$(grep PLACEMENT_PASSWORD ../.env | cut -d '=' -f2)" $(grep PLACEMENT_USER ../.env | cut -d '=' -f2)
openstack role add --project service --user $(grep PLACEMENT_USER ../.env | cut -d '=' -f2) admin

# Create the Placement API entry in the service catalog
echo "create API entry in the service catalog"
openstack service create --name $(grep PLACEMENT_USER ../.env | cut -d '=' -f2) --description "Placement API" placement

# Create the Placement API service endpoints
echo "creating API service endpoints"
openstack endpoint create --region RegionOne placement public http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8778
openstack endpoint create --region RegionOne placement internal http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8778
openstack endpoint create --region RegionOne placement admin http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):8778

# install placement api
echo "installing placement-api"
apt install -y placement-api

# edit placement.conf
echo "editing placement.conf"

crudini --set /etc/placement/placement.conf connection mysql+pymysql://$(grep PLACEMENT_DB_USER ../.env | cut -d '=' -f2):$(grep PLACEMENT_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep PLACEMENT_DB_NAME ../.env | cut -d '=' -f2)

crudini --set /etc/placement/placement.conf api auth_strategy keystone 

crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000 
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers $(grep DEFAULT_URL ../.env | cut -d '=' -f2):11211 
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password 
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service 
crudini --set /etc/placement/placement.conf keystone_authtoken username $(grep PLACEMENT_USER ../.env | cut -d '=' -f2)
crudini --set /etc/placement/placement.conf keystone_authtoken password $(grep PLACEMENT_PASSWORD ../.env | cut -d '=' -f2)

# populate placement database
echo "populate placement database"
su -s /bin/sh -c "placement-manage db sync" placement

# restart server
echo "restart apache2 server"
service apache2 restart






