!/bin/bash

#          install.sh, 'ProAlert' configuration script.
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

yum clean all
yum update -y

###   ###   Install APACHE   ###   ###

APACHE_INSTALLED=$(which httpd)
if [[ "$APACHE_INSTALLED" == "" ]]
then
  printf "\n\n Installing Apache ...\n"
  
  yum install httpd -y
  systemctl start httpd.service
  systemctl enable httpd.service
  firewall-cmd --permanent --add-port=8080/tcp

  mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.dissabled
  systemctl restart httpd.service

  APACHE_INSTALLED=$(which httpd)
    if [[ "$APACHE_INSTALLED" == "" ]]
    then
      printf "\n\n EXITING : Apache installation FAILED\n"
      exit 1
    fi
else
  printf "\n\n Apache is already installed. \n"
fi

###   ###   Install MySQL   ###   ###

MYSQL_INSTALLED=$(which mysql)
if [[ "$MYSQL_INSTALLED" == "" ]]
then
  printf "\n\n Installing MYSQL ...\n"
  
  yum install mariadb-server mariadb -y

  systemctl start mariadb.service
  systemctl enable mariadb.service

  MYSQL_INSTALLED=$(which mysql)
    if [[ "$MYSQL_INSTALLED" == "" ]]
    then
      printf "\n\n EXITING : MYSQL installation FAILED\n"
      exit 1
    fi
else
  printf "\n\n MYSQL is already installed. \n"
fi

###   ###   Install PHP   ###   ###

PHP_INSTALLED=$(which php)
if [[ "$PHP_INSTALLED" == "" ]]
then
  printf "\n\n Installing PHP ...\n"
  
  yum install php php-mysql -y

  systemctl restart httpd.service

  PHP_INSTALLED=$(which php)
    if [[ "$PHP_INSTALLED" == "" ]]
    then
      printf "\n\n EXITING : PHP installation FAILED\n"
      exit 1
    fi
else
  printf "\n\n PHP is already installed. \n"
fi

###   ###   Install ProAlert   ###   ###

if [ ! -f "/opt/proalert/app/README.md" ]
then
  printf "\n\n Installing ProAlert ...\n"
  
#  mkdir -p "/opt/proalert/app" 
#  cd /opt/proalert/app

  if [ -d "/opt/proalert/app" ]
  then
    rm -rf "/opt/proalert/app"
  fi

  if [ -d "/var/www/proalert" ]
  then
    rm -rf "/var/www/proalert"
  fi


  wget https://github.com/JeffreyPowell/proalert/archive/master.zip

  unzip master.zip -d /opt/proalert

fi



