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
CREATE TABLE IF NOT EXISTS systems    (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL,
                                            url           varchar(256)  NOT NULL,
                                            port          smallint(6)    NOT NULL,
                                            tier_id       int(11)       DEFAULT NULL );
CREATE TABLE IF NOT EXISTS metrics    (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL,
                                            query         varchar(1024) NOT NULL );
CREATE TABLE IF NOT EXISTS channels   (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL,
                                            action        varchar(1024) NOT NULL );
CREATE TABLE IF NOT EXISTS alerts     (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            system_id     int(11)       NOT NULL,
                                            metric_id     int(11)       NOT NULL,
                                            trigger_value float         NOT NULL,
                                            trigger_opp   char(1)       NOT NULL,
                                            channel_id    int(11)       NOT NULL,
                                            status        tinyint(1)    DEFAULT 0 );
CREATE TABLE IF NOT EXISTS tiers      (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL );
CREATE TABLE IF NOT EXISTS conf       (      id            int(11)       NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                            name          varchar(256)  NOT NULL 
                                            value         text          NOT NULL);                                           
                                            
                                            
DATABASE

cat > /opt/proalert/proalert-master/config.ini <<CONFIG
[db]
server = $DB_SERVER
user = $DB_USERNAME
password = $DB_PASSWORD
database = $DB_NAME
CONFIG
