CREATE DATABASE IF NOT EXISTS nova;

CREATE USER IF NOT EXISTS 'nova'@'%' IDENTIFIED BY 'anq9SXHR';

GRANT ALL PRIVILEGES ON placement.* TO 'nova'@'%';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost';