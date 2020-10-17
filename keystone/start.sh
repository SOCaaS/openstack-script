apt update
apt upgrade -y
echo $(grep MYSQL_HOST .env | cut -d '=' -f2)

# run keystone.sql
mysql -u root -p < keystone.sql

# Install keystone
echo "Installing keystone"
apt install -y keystone

# edit keystone.conf
sed -i -e "s|^connection = .*|connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone|g" /etc/keystone/keystone.conf

sed -i -e "s|^provider = .*|provider = fernet|g" /etc/keystone/keystone.conf