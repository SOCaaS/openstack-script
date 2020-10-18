CREATE DATABASE IF NOT EXISTS keystone;

CREATE USER 'keystone'@'localhost' IDENTIFIED BY 'NCQhEHRb';
CREATE USER 'keystone'@'%' IDENTIFIED BY 'NCQhEHRb';

GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'NCQhEHRb';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'NCQhEHRb';


