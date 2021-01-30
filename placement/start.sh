set -e
apt update


# run placement.sql
echo -e "\n Create a placement sql user"

sed -i -e "s|{{ PLACEMENT_DB_NAME }}|$PLACEMENT_DB_NAME|g" ./placement.sql
sed -i -e "s|{{ PLACEMENT_DB_USER }}|$PLACEMENT_DB_USER|g" ./placement.sql
sed -i -e "s|{{ PLACEMENT_DB_PASSWORD }}|$PLACEMENT_DB_PASSWORD|g" ./placement.sql

mysql -e "source placement.sql";

# export variables
echo -e "\nExport environment variable"
export OS_USERNAME=$OS_USERNAME
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

# create placement user and give admin role
echo "creating openstack user 'placement'"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$PLACEMENT_PASSWORD" $PLACEMENT_USER
openstack role add --project service --user $PLACEMENT_USER admin

# Create the Placement API entry in the service catalog
echo "create API entry in the service catalog"
openstack service create --name $PLACEMENT_USER --description "Placement API" placement

# Create the Placement API service endpoints
echo "creating API service endpoints"
openstack endpoint create --region RegionOne placement public http://$DEFAULT_URL:8778
openstack endpoint create --region RegionOne placement internal http://$DEFAULT_URL:8778
openstack endpoint create --region RegionOne placement admin http://$DEFAULT_URL:8778

# install placement api
echo "installing placement-api"
apt install -y placement-api

# edit placement.conf
echo "editing placement.conf"

crudini --set /etc/placement/placement.conf connection mysql+pymysql://$PLACEMENT_DB_USER:$PLACEMENT_DB_PASSWORD@$DEFAULT_URL/$PLACEMENT_DB_NAME

crudini --set /etc/placement/placement.conf api auth_strategy keystone 

crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://$DEFAULT_URL:5000 
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers $DEFAULT_URL:11211 
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password 
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service 
crudini --set /etc/placement/placement.conf keystone_authtoken username $PLACEMENT_USER
crudini --set /etc/placement/placement.conf keystone_authtoken password $PLACEMENT_PASSWORD

# populate placement database
echo "populate placement database"
su -s /bin/sh -c "placement-manage db sync" placement

# restart server
echo "restart apache2 server"
service apache2 restart






