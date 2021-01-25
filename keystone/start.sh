set -e
apt update


sed -i -e "s|{{ KEYSTONE_DB_NAME }}|$(grep KEYSTONE_DB_NAME ../.env | cut -d '=' -f2)|g"  ./keystone.sql
sed -i -e "s|{{ KEYSTONE_DB_USER }}|$(grep KEYSTONE_DB_USER ../.env | cut -d '=' -f2)|g"  ./keystone.sql
sed -i -e "s|{{ KEYSTONE_DB_PASSWORD }}|$(grep KEYSTONE_DB_PASSWORD ../.env | cut -d '=' -f2)|g"  ./keystone.sql

# run keystone.sql
mysql -e "source keystone.sql";

# Install keystone
echo "Installing keystone"
apt install -y keystone

# edit keystone.conf
echo "editing keystone.conf"
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://$(grep KEYSTONE_DB_USER ../.env | cut -d '=' -f2):$(grep KEYSTONE_DB_PASSWORD ../.env | cut -d '=' -f2)@$(grep DEFAULT_URL ../.env | cut -d '=' -f2)/$(grep KEYSTONE_DB_NAME ../.env | cut -d '=' -f2)

crudini --set /etc/keystone/keystone.conf token provider fernet

# Populate the Identity service database
echo "populating the identity service database"
set +e
su -s /bin/sh -c "keystone-manage db_sync" keystone
set -e

# Initialize Fernet key repositories
echo "initializing Fernet key repositories"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap the Identity service
echo "bootstrap identity services"
keystone-manage bootstrap --bootstrap-password $(grep OS_PASSWORD ../.env | cut -d '=' -f2) \
  --bootstrap-admin-url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/v3/ \
  --bootstrap-internal-url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/v3/ \
  --bootstrap-public-url http://$(grep DEFAULT_URL ../.env | cut -d '=' -f2):5000/v3/ \
  --bootstrap-region-id RegionOne


# set servername to controller
echo "Servername set to controller"
sed -i "1 i\ServerName $(grep DEFAULT_URL ../.env | cut -d '=' -f2)" /etc/apache2/apache2.conf

# restart apache server
echo "Restarting apache2"
service apache2 restart
