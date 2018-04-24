#!/bin/bash

printf "\n\n\n Please enter the MySQL root password : "
read -s ROOT_PASSWORD

DB_USERNAME='pauser'
DB_PASSWORD=$(date | md5sum | head -c12)
DB_SERVER='localhost'
DB_NAME='proalert'

echo
echo $DB_PASSWORD
echo

mysql -uroot -p$ROOT_PASSWORD<< DATABASE
CREATE DATABASE $DB_NAME CHARACTER SET = utf8;
CREATE USER '$DB_USERNAME'@'$DB_SERVER';
SET PASSWORD FOR '$DB_USERNAME'@'$DB_SERVER' = PASSWORD('$DB_PASSWORD');
GRANT ALL ON $DB_NAME.* TO '$DB_USERNAME'@'$DB_SERVER';
FLUSH PRIVILEGES;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS systems   (      s_id          int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL,
                                            pin           int(11)       DEFAULT NULL,
                                            active_level  tinyint(4)    DEFAULT NULL,
                                            value         tinyint(1)    DEFAULT 0 );
CREATE TABLE IF NOT EXISTS slevel   (      id            bigint(11)    NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            ref           varchar(20)   DEFAULT NULL,
                                            name          varchar(256)  DEFAULT NULL,
                                            ip            varchar(16)   DEFAULT NULL,
                                            value         float         DEFAULT NULL,
                                            unit          varchar(11)   NOT NULL );

DATABASE

cat > /opt/proadmin/proadmin-master/config.ini <<CONFIG
[db]
server = $DB_SERVER
user = $DB_USERNAME
password = $DB_PASSWORD
database = $DB_NAME
CONFIG
