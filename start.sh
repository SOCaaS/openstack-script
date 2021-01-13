echo -e "Start All Service at Once!"
echo -e "\nStart base Openstack!"
cd ./Openstack-Base
./start.sh
cd ..

echo -e "\nStart Keystone!"
cd ./keystone
./start.sh
cd ..

echo -e "\nStart Glance!"
cd ./glance
./start.sh
cd ..

echo -e "\nStart Placement!"
cd ./placement
./start.sh
cd ..

echo -e "\nStart Nova!"
cd ./Nova
./start.sh
cd ..

echo -e "\nStart Neutron!"
cd ./neutron
./start.sh
cd ..

echo -e "\nStart Horizon!"
cd ./horizon
./start.sh
cd ..

echo -e "Finish, all service has been deployed!"