set -e

echo -e "\nExecute Flavor Creation"
openstack flavor create --ram 512 --vcpus 1 --disk 30 --public --project-domain $OS_PROJECT_DOMAIN_NAME s1.mini
openstack flavor create --ram 1024 --vcpus 1 --disk 30 --public --project-domain $OS_PROJECT_DOMAIN_NAME s1.tall
openstack flavor create --ram 1024 --vcpus 2 --disk 30 --public --project-domain $OS_PROJECT_DOMAIN_NAME s1.grande
openstack flavor create --ram 2048 --vcpus 2 --disk 30 --public --project-domain $OS_PROJECT_DOMAIN_NAME s1.venti
openstack flavor create --ram 4096 --vcpus 4 --disk 30 --public --project-domain $OS_PROJECT_DOMAIN_NAME s1.trenta

openstack flavor list