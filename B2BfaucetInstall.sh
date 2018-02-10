#!/bin/bash
# read the users password for the B2B faucet database
echo "Choose a password to use in the B2B Faucet Database."
read -s -p "Password: " DATABASE_PASS
echo 
read -s -p "Password (again): " DATABASE_PASS2

# check if passwords match and if not ask again
while [ "$DATABASE_PASS" != "$DATABASE_PASS2" ];
do
    echo 
    echo "The passwords did not match, please try again..."
    read -s -p "Password: " DATABASE_PASS
    echo
    read -s -p "Password (again): " DATABASE_PASS2
done

# Remove Postfix to prevent the installation from being stopped...
apt-get -y purge --auto-remove postfix

# Make sure the system is up to date...
apt-get update -y && apt-get upgrade -y
 
# Install everything we need to setup the B2B faucet...
apt-get -y install nano php5-mysql php5 libapache2-mod-php5 php5-mcrypt php5-gd php5-curl debconf-utils git

# Make sure index.php is loaded before index.html
sed -i 's/index.html index.cgi index.pl index.php/index.php index.html index.cgi index.pl/g' /etc/apache2/mods-enabled/dir.conf

# Download the B2B faucet...
git clone https://github.com/PorkyForky/b2bcoin-faucet

# Delete the preinstalled index.html file...
rm /var/www/html/index.html

# Copy the B2B faucet to the web folder...
cp -a b2bcoin-faucet/. /var/www/html/ 

# Install MySQL...
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '"$DATABASE_PASS"''
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '"$DATABASE_PASS"''
apt-get -y install mysql-server
mysql_install_db 

# Create the B2B faucet Database...
mysql -uroot -p"$DATABASE_PASS" -e "create database B2BfaucetDB;"

# Secure the Database...
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Edit the config.php
sed -i 's/your_user/root/g' /var/www/html/config.php
sed -i 's/your_password/'"$DATABASE_PASS"'/g' /var/www/html/config.php
sed -i 's/your_db_name/B2BfaucetDB/g' /var/www/html/config.php

echo
echo "The B2B faucet is now installed on your VPS... Use your web browser and go to http://your.vps.ip.here"
echo
