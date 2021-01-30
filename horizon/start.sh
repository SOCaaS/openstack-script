set -e
apt update



# Install horizon
echo -e "\nInstalling horizon"
apt install -y openstack-dashboard

# edit horizon settings
echo -e "\nEditing horizon settings"
# openstack host
cp ./local_settings.py /etc/openstack-dashboard/local_settings.py

echo -e "\nReload web server config"
systemctl reload apache2.service


