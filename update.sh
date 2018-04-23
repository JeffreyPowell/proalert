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
  
  rm -rf /opt/proalert/master.zip*
  rm -rf /opt/proalert/proalert-master

  wget https://github.com/JeffreyPowell/proalert/archive/master.zip

  unzip master.zip -d /opt/proalert

  rm -rf /opt/proalert/master.zip*


  rm -rf /var/www/proalert/*

  mv  "/opt/proalert/proalert-master/html" "/var/www/proalert/public_html"  

  chown -R prometheus:apache "/var/www/proalert"
  chmod -R 770 "/var/www/proalert"


  systemctl restart httpd.service

else
  printf "\n\n ProAlert is not installed. \n"
fi


printf "\n\n Installation Complete. Some changes might require a reboot. \n\n"
exit 1
