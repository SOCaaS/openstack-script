CREATE DATABASE IF NOT EXISTS glance;

CREATE USER 'glance'@'localhost' IDENTIFIED BY '837ruyDA312y23djs';
CREATE USER 'glance'@'%' IDENTIFIED BY '837ruyDA312y23djs'

GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%';
