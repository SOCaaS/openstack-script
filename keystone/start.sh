apt update
apt upgrade -y
echo $(grep MYSQL_HOST .env | cut -d '=' -f2)

# run keystone.sql
mysql -e "source keystone.sql";

# Install keystone
echo "Installing keystone"
apt install -y keystone

# edit keystone.conf
sed -i -e "s|^connection = .*|connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone|g" /etc/keystone/keystone.conf

sed -i -e "s|^provider = .*|provider = fernet|g" /etc/keystone/keystone.conf

# Populate the Identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet key repositories
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap the Identity service
keystone-manage bootstrap --bootstrap-password 9zExzZzL \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# set servername to controller
sed -i -e "s|^ServerName .*|ServerName controller|g" /etc/apache2/apache2.conf

# restart apache server
service apache2 restart

# set env variables	
$ export OS_USERNAME=admin
$ export OS_PASSWORD=9zExzZzL
$ export OS_PROJECT_NAME=admin
$ export OS_USER_DOMAIN_NAME=Default
$ export OS_PROJECT_DOMAIN_NAME=Default
$ export OS_AUTH_URL=http://controller:5000/v3
$ export OS_IDENTITY_API_VERSION=3

# install openstack train
#


















