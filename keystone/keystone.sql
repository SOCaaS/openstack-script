CREATE DATABASE  keystone;

CREATE USER 'keystone'@'localhost'

GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'NCQhEHRb';

/*
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'NCQhEHRb';
*/

