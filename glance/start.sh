set -e 

mysql -e "source glance.sql";

. admin-openrc

openstack user create --domain default --password "yrgehdbsjkhu32897124" glance

openstack role add --project service --user glance admin

zypper install openstack-glance