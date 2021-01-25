set -e
apt update
apt upgrade -y

echo -e "\n Create a CINDER sql user"
sed -i -e "s|{{ CINDER_DB_NAME }}|$(grep CINDER_DB_NAME ../.env | cut -d '=' -f2)|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_USER }}|$(grep CINDER_DB_USER ../.env | cut -d '=' -f2)|g" ./cinder.sql
sed -i -e "s|{{ CINDER_DB_PASSWORD }}|$(grep CINDER_DB_PASSWORD ../.env | cut -d '=' -f2)|g" ./cinder.sql

# Export environment variable
echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
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
openstack endpoint create --region RegionOne volumev2 public http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://controller:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://controller:8776/v3/%\(project_id\)s

