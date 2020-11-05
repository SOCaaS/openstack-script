set -e
apt update
apt upgrade -y


# Install horizon
echo "Installing horizon"
apt install -y openstack-dashboard

# edit horizon settings
echo "editing horizon settings"
# openstack host
sed -i -e "s|^OPENSTACK_HOST = .*|OPENSTACK_HOST = \"controller\"|g" /etc/openstack-dashboard/local_settings.py

# keystone url
sed -i -e "s|^OPENSTACK_KEYSTONE_URL = .*|OPENSTACK_KEYSTONE_URL = \"http://%s:5000/v3\" % OPENSTACK_HOST|g" /etc/openstack-dashboard/local_settings.py

echo "reload web server config"
systemctl reload apache2.service


