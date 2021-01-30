set -e




echo -e "\nExecute Flavor Creation"
openstack flavor create --ram 512 --vcpus 1 --project service --project-domain $OS_PROJECT_DOMAIN_NAME s1.mini

openstack flavor list