CREATE DATABASE IF NOT EXISTS placement;

CREATE USER 'placement'@'localhost' IDENTIFIED BY 'anq9SXHR';
CREATE USER 'placement'@'%' IDENTIFIED BY 'anq9SXHR';

GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%';


