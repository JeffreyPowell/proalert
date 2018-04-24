#!/bin/bash

#          update.sh, 'ProAlert' update script.
# Author : Jeffrey.Powell ( jffrypwll <at> googlemail <dot> com )
# Date   : April 2018

# Die on any errors

#set -e
clear

if [[ `whoami` != "root" ]]
then
  printf "\n\n Script must be run as root. \n\n"
  exit 1
fi

OS_VERSION=$(cat /etc/os-release)
OS_REQUIRED="Centos-7"
if [[ "$OS_VERSION" =~ "$OS_REQUIRED" ]]
then
  printf "\n\n This script is designed for installation on CentOS 7 ...\n"
  printf "\n\n EXITING : installation FAILED\n\n\n\n"
  exit 1
fi

# yum clean all
# yum update -y



###   ###   Update ProAlert   ###   ###

if [ -d "/opt/proalert/proalert-master" ]
then
  printf "\n\n Updating ProAlert ...\n"
  
  cd /opt/proalert
  
  # save config file
  rm -f /tmp/proalert-config.tmp
  mv /opt/proalert/proalert-master/config.ini /tmp/proalert-config.tmp
  
  # remove existing files
  rm -rf /opt/proalert/master.zip*
  rm -rf /opt/proalert/proalert-master
  rm -rf /var/www/proalert/*

  # download master branch
  wget https://github.com/JeffreyPowell/proalert/archive/master.zip
  unzip master.zip -d /opt/proalert
  rm -rf /opt/proalert/master.zip*
  
  # restore config file
  rm /opt/proalert/proalert-master/config.ini
  mv /tmp/proalert-config.tmp /opt/proalert/proalert-master/config.ini
  rm -f /tmp/proalert-config.tmp
  
  # move www files to web directory
  mv  "/opt/proalert/proalert-master/html" "/var/www/proalert/public_html"  
  chown -R prometheus:apache "/var/www/proalert"
  chmod -R 770 "/var/www/proalert"

  # restart apache
  systemctl restart httpd.service

else
  printf "\n\n ProAlert is not installed. \n"
fi

exit 1
