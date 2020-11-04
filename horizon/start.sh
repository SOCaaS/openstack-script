set -e
apt update
apt upgrade -y


# Install horizon
echo "Installing horizon"
apt install -y openstack-dashboard

# edit horizon settings
echo "editing horizon settings"
# openstck host
sed -i -e "s|^OPENSTACK_HOST = .*|OPENSTACK_HOST = \"controller\"|g" /etc/openstack-dashboard/local_settings.py

# allowed hosts
sed -i -e "s|^ALLOWED_HOSTS = .*|ALLOWED_HOSTS = ['*']|g" /etc/openstack-dashboard/local_settings.py

# session engine
sed -i -e "s|^SESSION_ENGINE = .*|SESSION_ENGINE = 'django.contrib.sessions.backends.cache'|g" /etc/openstack-dashboard/local_settings.py

# cache setting
sed -i -e "s|^CACHES = .*|CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}|g" /etc/openstack-dashboard/local_settings.py

# keystone url
sed -i -e "s|^OPENSTACK_KEYSTONE_URL = .*|OPENSTACK_KEYSTONE_URL = \"http://%s/identity/v3\" % OPENSTACK_HOST|g" /etc/openstack-dashboard/local_settings.py

# API ver
sed -i -e "s|^OPENSTACK_API_VERSIONS = .*|OPENSTACK_API_VERSIONS = {\"identity\": 3, \"image\": 2, \"volume\": 3,}|g" /etc/openstack-dashboard/local_settings.py

# default domain
sed -i -e "s|^OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = .*|OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = \"Default\"|g" /etc/openstack-dashboard/local_settings.py

# default role
sed -i -e "s|^OPENSTACK_KEYSTONE_DEFAULT_ROLE = .*|OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"|g" /etc/openstack-dashboard/local_settings.py

# openstack neutron network
# If you chose networking option 1, disable support for layer-3 networking services:

#OPENSTACK_NEUTRON_NETWORK = {
#    ...
#    'enable_quotas': False,
#    'enable_ipv6': False,
#    'enable_distributed_router': False,
#    'enable_ha_router': False,
#    'enable_lb': False,
#    'enable_firewall': False,
#    'enable_vpn': False,
#    'enable_fip_topology_check': False,
#}

sed -i -e "s|^'enable_quotas' : .*|'enable_quotas' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_ipv6' : .*|'enable_ipv6' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_distributed_router' : .*|'enable_distributed_router' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_ha_router' : .*|'enable_ha_router' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_lb' : .*|'enable_lb' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_firewall' : .*|'enable_firewall' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_vpn' : .*|'enable_vpn' : False,|g" /etc/openstack-dashboard/local_settings.py
sed -i -e "s|^'enable_fip_topology_check' : .*|'enable_fip_topology_check' : False,|g" /etc/openstack-dashboard/local_settings.py

# time zone setting
sed -i -e "s|^TIME_ZONE = .*|TIME_ZONE = \"AU\"|g" /etc/openstack-dashboard/local_settings.py

echo "WSGIApplicationGroup %{GLOBAL}" >> /etc/apache2/conf-available/openstack-dashboard.conf

echo "reload web server config"
systemctl reload apache2.service


