#!/bin/bash

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

# yum clean all
# yum update -y

###   ###   Dissable SELINUX   ###   ###

setenforce 0

 cat > /etc/sysconfig/selinux <<DESELINUX
SELINUX=disabled
DESELINUX



###   ###   Install APACHE   ###   ###

APACHE_INSTALLED=$(which httpd)
if [[ "$APACHE_INSTALLED" == "" ]]
then
  printf "\n\n Installing Apache ...\n"
  
  yum install httpd -y
  systemctl start httpd.service
  systemctl enable httpd.service
  firewall-cmd --permanent --add-port=8080/tcp

  mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.disabled
  
  echo "IncludeOptional sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
  mkdir /etc/httpd/sites-available
  mkdir /etc/httpd/sites-enabled

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
  
  yum install mariadb-server mariadb MySQL-python -y

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

if [ ! -d "/opt/proalert/proalert-master" ]
then
  printf "\n\n Installing ProAlert ...\n"
  
#  mkdir -p "/opt/proalert/app" 
#  cd /opt/proalert/app

#  if [ -d "/opt/proalert/proalert-master" ]
#  then
#    rm -rf "/opt/proalert/proalert-master"
#    rm -rf /opt/proalert/master.zip*    
#  fi


  rm -rf /opt/proalert/master.zip*

  yum install python-requests
  
  wget https://github.com/JeffreyPowell/proalert/archive/master.zip

  unzip master.zip -d /opt/proalert

  rm -rf /opt/proalert/master.zip*


  rm -rf /var/www/proalert

  mkdir -p /var/www/proalert

  mv  "/opt/proalert/proalert-master/html" "/var/www/proalert/public_html"  

  useradd prometheus
  
  chown -R prometheus:apache "/var/www/proalert"
  chmod -R 770 "/var/www/proalert"

  rm -f /etc/httpd/sites-available/proalert.conf
  rm -f /etc/httpd/sites-enabled/proalert.conf


  echo "Listen 8080" >> /etc/httpd/conf/httpd.conf

  cat > /etc/httpd/sites-available/proalert.conf <<VHOST
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/proalert/public_html/
    <Directory /var/www/proalert/public_html/>
        Options -Indexes
        AllowOverride all
        Order allow,deny
        allow from all
    </Directory>
    ErrorLog /var/www/proalert/error.log
    CustomLog /var/www/proalert/access.log combined
</VirtualHost>
VHOST


  ln -s /etc/httpd/sites-available/proalert.conf /etc/httpd/sites-enabled/proalert.conf


  systemctl restart httpd.service

else
  printf "\n\n ProAlert is already installed. \n"
fi


printf "\n\n Installation Complete. Some changes might require a reboot. \n\n"
exit 1
