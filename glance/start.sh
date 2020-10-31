set -e
apt update
apt upgrade -y

echo -e "\nCreate a glance sql user"
mysql -e "source glance.sql";

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=admin
export OS_PASSWORD=9zExzZzL
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

echo -e "\nCreate openstack user on keystone"
openstack user create --domain default --password "yrgehdbsjkhu32897124" glance

echo -e "\nCreate a project"
openstack project create --domain default --description "Service Project" service
openstack role add --project service --user glance admin

echo -e "\nCreate the glance service entity"
openstack service create --name glance --description "OpenStack Image" image

echo -e "\nCreate the Image service API endpoint"
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

echo -e "\nInstall and configure components"
apt install -y glance

echo -e "\nEditing glance-api.conf"
sed -i -e "s|^connection = .*|connection = mysql+pymysql://glance:837ruyDA312y23djs@controller/glance|g" /etc/glance/glance-api.conf

sed -i -e '/^\[keystone_authtoken\]/a\' -e "www_authenticate_uri = http://controller:5000" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "memcached_servers = controller:11211" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "auth_type = password" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_domain_name = Default" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "user_domain_name = Default" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "project_name = service" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "username = glance" /etc/glance/glance-api.conf
sed -i -e '/^\[keystone_authtoken\]/a\' -e "password = yrgehdbsjkhu32897124" /etc/glance/glance-api.conf

sed -i -e '/^\[paste_deploy\]/a\' -e 'flavor = keystone' /etc/glance/glance-api.conf

sed -i -e '/^\[glance_store\]/a\' -e 's|^stores = .*|stores = file,http|g' /etc/glance/glance-api.conf
sed -i -e '/^\[glance_store\]/a\' -e 'default_store = file' /etc/glance/glance-api.conf
sed -i -e '/^\[glance_store\]/a\' -e 'filesystem_store_datadir = /var/lib/glance/images/' /etc/glance/glance-api.conf

echo -e "\nDB Sync Glance"
set +e
su -s /bin/sh -c "glance-manage db_sync" glance
set -e

echo -e "\nGlance Restart"
service glance-api restart
