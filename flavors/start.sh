set -e

echo -e "\nExport environment variable"
export OS_USERNAME=$(grep OS_USERNAME ../.env | cut -d '=' -f2)
export OS_PASSWORD=$(grep OS_PASSWORD ../.env | cut -d '=' -f2)
export OS_PROJECT_NAME=$(grep OS_PROJECT_NAME ../.env | cut -d '=' -f2)
export OS_USER_DOMAIN_NAME=$(grep OS_USER_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_PROJECT_DOMAIN_NAME=$(grep OS_PROJECT_DOMAIN_NAME ../.env | cut -d '=' -f2)
export OS_AUTH_URL=$(grep OS_AUTH_URL ../.env | cut -d '=' -f2)
export OS_IDENTITY_API_VERSION=$(grep OS_IDENTITY_API_VERSION ../.env | cut -d '=' -f2)


echo -e "\nExecute Flavor Creation"
openstack flavor create --ram 512 --vcpus 1 --project service --project-domain $OS_PROJECT_DOMAIN_NAME s1.mini

openstack flavor list