#!/bin/bash
# This script installs Lamp Server on Redhat 8."
# (c) 2022 Unix Training Academy, Inc. Freeware.
echo
echo "This script installs Lamp Server on Redhat 8."
echo "(c) 2022 Elias Igwegbu."
echo
echo "First, a few seconds pause for the great people of Ukraine..."
sleep 5
echo
echo "******* STEP 1: Update RHEL8 Software Packages *******"
echo
echo "Updating the OS ..."
sudo dnf -y update
echo
echo "Installing the required packages..."
echo
echo "Installing Fedoraproject..."
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
echo
echo "Installing dnf-utils..."
sudo dnf -y install dnf-utils
echo
echo "Installing remirepo..."
sudo dnf -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm
echo
echo "******* STEP 2: Install Apache Web Server on RHEL 8 *******"
echo
sudo dnf install -y httpd httpd-tools
echo
echo "Starting and enabling the httpd service..."
sudo systemctl enable --now httpd
sudo systemctl status httpd | head
httpd -v
echo
echo "Setting up the firewall service..."
echo "http service..."
sudo firewall-cmd --zone=public --add-service=http
echo "https service..."
sudo firewall-cmd --zone=public --add-service=https
echo "http port 80..."
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
echo "https port 443..."
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
echo "Reloading firewall-cmd..."
sudo firewall-cmd --reload
echo 
echo "******* STEP 3: Install MariaDB on RHEL 8 *******"
echo
echo "Installing mariadb-server and mariadb daemon..."
sudo dnf install -y mariadb-server mariadb
echo
echo "Starting and enabling mariadb..."
sudo systemctl enable --now mariadb
sudo systemctl status mariadb | head
echo "Securing mariadb server..."
sudo mysql_secure_installation
echo
echo "Finished installing Mariadb."
echo
echo " ******   NOTICE     *****"
echo
echo "Next, we will login to Mariadb, and:"
echo "	1. create a database named classroaster thus:"
echo '		>create database classroaster;'
echo "	2. create a user named oracle with password 123456 thus:"
echo "		>create user oracle@localhost identified with '123456';"
echo "	3. grant the user necessary privileges thus:"
echo '		>grant all privileges on classroaster.* to '
echo "		 oracle@localhost identified by '123456';"
echo 
echo "Login to the database as root:"
mysql -u root -p
# user can test mysql commands interactively now, 
# then return to script by typing exit; or quit; 
echo 
echo "******* Step 4: Install PHP 7 on RHEL 8 *******"
echo
echo "Displaying PHP modules available for installation..."
sudo dnf module list php
sleep 5
echo "Resetting the PHP modules..."
sudo dnf module reset -y php
sleep 5
echo "Enabling remi-7.4 PHP module..."
sudo dnf module enable -y php:remi-7.4
sleep 5
echo "Installing PHP and associated packages..."
sudo dnf install -y php php-opcache php-gd php-curl php-mysqlnd
php -v
echo "Starting and enabling PHP..."
sudo systemctl enable --now php-fpm
sudo systemctl status php-fpm | head
echo
echo "Now configuring SELinux to allow Appache to execute"
echo "PHP code via PHP-FPM run..."
sudo setsebool -P httpd_execmem 1
echo
echo "Restarting the Apache web server daemon..."
sudo systemctl restart httpd
echo
echo "Now creating a test PHP page..."
sudo echo '<?php' > /var/www/html/info.php
sudo echo 'phpinfo ();' >> /var/www/html/info.php
sudo echo '?>' >> /var/www/html/info.php
sleep 5
echo
echo "PHP installation complete."
echo 'Try the PHP test page http://<your-server-ip-address>/info.php.'
echo
echo "Lamp Installation completed successfully."
echo
echo "Now Installing Wordpress..."
echo
sudo cd /tmp
echo "Downloading the WordPress installation archive..."
sudo dnf -y install wget
sudo wget http://wordpress.org/latest.tar.gz
echo 'Extracting the archive into the /tmp directory...'
sudo tar -xvzf latest.tar.gz
echo
echo "Building the wordpress root directory..."
sudo cp -r wordpress/* /var/www/html
sudo mkdir -p /var/www/html/wp-content/uploads
sudo chown -R apache:apache /var/www/html/*
# sudo cd /var/www/html
cd /var/www/html
# pwd
echo
sudo cp wp-config-sample.php wp-config.php

#Use sed to edit the php file in place
sudo sed -i 's/database_name_here/classroaster/g' wp-config.php
sudo sed -i 's/username_here/oracle/g' wp-config.php
sudo sed -i 's/password_here/123456/g' wp-config.php

cd
echo
echo "Finished WordPress configuration."
echo
echo "Now open http://<your-server-ip-address>/index.php' on your browser to complete the Wordpress installation."
echo
echo "******* THE END *******" 
echo
echo "Thank you for choosing Lamp Stack with WordPress!"
echo
echo '>>LAMP Server Installer version 1.0. (c) 2022. EC Igwegbu. All Rights Reserved.<<'
