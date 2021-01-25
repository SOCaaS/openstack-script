set -e
apt update



# Install horizon
echo "Installing horizon"
apt install -y openstack-dashboard

# edit horizon settings
echo "editing horizon settings"
# openstack host
cp ./local_settings.py /etc/openstack-dashboard/local_settings.py

echo "reload web server config"
systemctl reload apache2.service


