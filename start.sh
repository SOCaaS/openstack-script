set -e
echo "Starting OpenStack Script!"

echo -e "\nCheck the Linux Version"
source /etc/lsb-release
if [ $DISTRIB_ID != Ubuntu ]
then
    echo -e "\nThis is not a Ubuntu System!"
    exit 1
fi

if [ -f .env ]
then
    echo -e "\nImporting .env to Environment Variable"
    set -o allexport; source .env; set +o allexport
else 
    echo -e "\nThere is no env file!"
    exit 1
fi

echo -e "\nStart base Openstack!"
cd ./openstack-base
./start.sh
cd ..

echo -e "\nStart Integration Stack!"
cd ./integration
./start.sh
cd ..

echo -e "\nStart Keystone!"
cd ./keystone
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Glance!"
cd ./glance
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nAdd Image!"
cd ./images
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Placement!"
cd ./placement
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Nova!"
cd ./nova
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Neutron!"
cd ./neutron
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Cinder!"
cd ./cinder
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nStart Horizon!"
cd ./horizon
./start.sh
cd ..

systemctl restart tailon.service

echo -e "\nAdd Flavors!"
cd ./flavors
./start.sh
cd ..

systemctl restart tailon.service

echo -e "Finish, all service has been deployed!"