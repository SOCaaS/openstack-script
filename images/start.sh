

echo -e "\nAdd cirros image"
wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create cirros3.5 --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public

echo -e "\nAdd Ubuntu focal image"
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
openstack image create ubuntu20.04 --file focal-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public

echo -e "\nList of images"
openstack image list