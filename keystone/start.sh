set -e
apt update

sed -i -e "s|{{ KEYSTONE_DB_NAME }}|$KEYSTONE_DB_NAME|g"  ./keystone.sql
sed -i -e "s|{{ KEYSTONE_DB_USER }}|$KEYSTONE_DB_USER|g"  ./keystone.sql
sed -i -e "s|{{ KEYSTONE_DB_PASSWORD }}|$KEYSTONE_DB_PASSWORD|g"  ./keystone.sql

# run keystone.sql
mysql -e "source keystone.sql";

# Install keystone
echo -e "\nInstalling keystone"
apt install -y keystone

# edit keystone.conf
echo -e "\nEditing keystone.conf"
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://$KEYSTONE_DB_USER:$KEYSTONE_DB_PASSWORD@$DEFAULT_URL/$KEYSTONE_DB_NAME

crudini --set /etc/keystone/keystone.conf token provider fernet

# Populate the Identity service database
echo -e "\nPopulating the identity service database"
set +e
su -s /bin/sh -c "keystone-manage db_sync" keystone
set -e

# Initialize Fernet key repositories
echo -e "\nInitializing Fernet key repositories"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap the Identity service
echo -e "\nBootstrap identity services"
keystone-manage bootstrap --bootstrap-password $OS_PASSWORD \
  --bootstrap-admin-url http://$DEFAULT_URL:5000/v3/ \
  --bootstrap-internal-url http://$DEFAULT_URL:5000/v3/ \
  --bootstrap-public-url http://$DEFAULT_URL:5000/v3/ \
  --bootstrap-region-id RegionOne


# set servername to controller
echo -e "\nServername set to controller"
sed -i "1 i\ServerName $DEFAULT_URL" /etc/apache2/apache2.conf

# restart apache server
echo -e "\nRestarting apache2"
service apache2 restart
