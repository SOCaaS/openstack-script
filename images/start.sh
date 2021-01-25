echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)

echo -e "\nAdd cirros images"
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create cirros3.5 --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public
openstack image list