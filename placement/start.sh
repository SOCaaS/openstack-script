set -e
apt update
apt upgrade -y

# run placement.sql
echo "run placement.sql"
mysql -e "source placement.sql";

# create placement user and give admin role
echo "creating openstack user 'placement'"
openstack user create --domain default --password v3hx4vBB placement
openstack role add --project service --user placement admin

# Create the Placement API entry in the service catalog
echo "create API entry in the service catalog"
openstack service create --name placement --description "Placement API" placement

# Create the Placement API service endpoints
echo "creating API service endpoints"
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

# install placement api
echo "installing placement-api"
apt install -y placement-api

# edit placement.conf
echo "editing placement.conf"

sed -i -e "s|^connection = .*|connection = mysql+pymysql://placement:anq9SXHR@controller/placement|g" /etc/placement/placement.conf

sed -i -e '/^\[api\]/a\' -e 'auth_strategy = keystone' /etc/placement/placement.conf

sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_url = http://controller:5000" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "memcached_servers = controller:11211" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_type = password" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_domain_name = Default" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "user_domain_name = Default" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_name = service" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "username = placement" /etc/placement/placement.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "password = v3hx4vBB" /etc/placement/placement.conf

# populate placement database
echo "populate placement database"
su -s /bin/sh -c "placement-manage db sync" placement

# restart server
echo "restart apache2 server"
service apache2 restart






