set -e
apt update


echo -e "\nCreate a glance sql user"

sed -i -e "s|{{ GLANCE_DB_NAME }}|$(grep GLANCE_DB_NAME ../.env | cut -d '=' -f2)|g" ./glance.sql
sed -i -e "s|{{ GLANCE_DB_USER }}|$(grep GLANCE_DB_USER ../.env | cut -d '=' -f2)|g" ./glance.sql
sed -i -e "s|{{ GLANCE_DB_PASSWORD }}|$(grep GLANCE_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./glance.sql

mysql -e "source glance.sql";

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

echo -e "\nCreate openstack user on keystone"
openstack user create --domain $OS_PROJECT_DOMAIN_NAME --password "$(grep GLANCE_PASSWORD ../.env | cut -d '=' -f2)" $(grep GLANCE_USER ../.env | cut -d '=' -f2)

echo -e "\nCreate a project"
openstack project create --domain $OS_PROJECT_DOMAIN_NAME --description "Service Project" service
openstack role add --project service --user $(grep GLANCE_USER ../.env | cut -d '=' -f2) admin

echo -e "\nCreate the glance service entity"
openstack service create --name $(grep GLANCE_USER ../.env | cut -d '=' -f2) --description "OpenStack Image" image

echo -e "\nCreate the Image service API endpoint"
openstack endpoint create --region RegionOne image public http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9292
openstack endpoint create --region RegionOne image internal http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9292
openstack endpoint create --region RegionOne image admin http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):9292

echo -e "\nInstall and configure components"
apt install -y glance

echo -e "\nEditing glance-api.conf"
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://$(grep GLANCE_DB_USER ../.env | cut -d '=' -f2):$(grep GLANCE_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep GLANCE_DB_NAME ../.env | cut -d '=' -f2)

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000 
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers $(grep DEFAULT_URL ../.env | cut -d '=' -f2):11211 
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password 
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username $(grep GLANCE_USER ../.env | cut -d '=' -f2)
crudini --set /etc/glance/glance-api.conf keystone_authtoken password $(grep GLANCE_PASSWORD ../.env | cut -d '=' -f2)

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone 

crudini --set /etc/glance/glance-api.conf glance_store stores "file,http" 
crudini --set /etc/glance/glance-api.conf glance_store default_store file 
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/ 

# echo -e "\nEditing glance-registry.conf"

# crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://$(grep GLANCE_DB_USER ../.env | cut -d '=' -f2):$(grep GLANCE_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep GLANCE_DB_NAME ../.env | cut -d '=' -f2)

# crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000 
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers $(grep DEFAULT_URL ../.env | cut -d '=' -f2):11211 
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password 
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name $OS_PROJECT_DOMAIN_NAME 
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name $OS_USER_DOMAIN_NAME
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken username $(grep GLANCE_USER ../.env | cut -d '=' -f2)
# crudini --set /etc/glance/glance-registry.conf keystone_authtoken password $(grep GLANCE_PASSWORD ../.env | cut -d '=' -f2)

# crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone 

echo -e "\nDB Sync Glance"
set +e
su -s /bin/sh -c "glance-manage db_sync" glance
set -e

echo -e "\nGlance Restart"
service glance-api restart

echo -e "\n Check Glance Status"
service glance-api status