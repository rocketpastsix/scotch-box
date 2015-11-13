#! /bin/bash

# Remove any existing aliases
# if [ -d /var/www/aliases ]; then
#   echo "Removing any existing aliases"
#   sudo find /var/www/aliases -maxdepth 1 -type l -exec rm -f {} \;
# else
#   echo "Creating new alias folder"
#   sudo mkdir /var/www/aliases
# fi

# cd /var/www/

# for d in /var/www/* ; do
#   BASE=$(basename $d);
#   if [ $BASE == 'aliases' ]; then
#     continue;
#   fi
#   DIR=$(dirname $d);

#   # @TODO find a nicer way to link to ruby from here
#   ALIAS=$(/home/vagrant/.rbenv/shims/ruby /vagrant/config.rb $BASE.local);

#   if [ ! -e $DIR/aliases/$BASE.local ]; then
#     echo "Creating new alias for $d/$ALIAS aliases/$BASE.local"
#     sudo ln -s $d/$ALIAS aliases/$BASE.local
#   fi

#   if [ ! -e $DIR/aliases/www.$BASE.local ]; then
#     echo "Creating new alias for  $d/$ALIAS  aliases/www.$BASE.local"
#     sudo ln -s $d/$ALIAS  aliases/www.$BASE.local
#   fi
# done

# Load in dumps
for f in /vagrant/dumps/*.sql ; do
  FILENAME=$(basename $f);
  DB=$(basename $f .sql)
  sudo echo "MYSQL: Importing $DB";
  mysql -uroot -proot -e "DROP DATABASE IF EXISTS $DB";
  mysql -uroot -proot -e "CREATE DATABASE $DB";
  mysql -uroot -proot $DB < /vagrant/dumps/$FILENAME;
done

# create and enable rewrite loader
echo "Creating Apache rewrite.load"
sudo echo "LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so" > /etc/apache2/mods-available/rewrite.load

# enable Apache mod_rewrite
sudo a2enmod rewrite

# create and enable vhost_alias loader
#echo "Creating Apache vhost_alias.load"
#sudo echo "LoadModule vhost_alias_module /usr/lib/apache2/modules/mod_vhost_alias.so" > /etc/apache2/mods-available/vhost_alias.load

# create our vhost_alias.conf file
#echo "Creating Apache vhost_alias.conf"
#sudo echo "UseCanonicalName Off" > /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "VirtualDocumentRoot /var/www/aliases/%0" >> /etc/apache2/mods-available/vhost_alias.conf

#sudo echo "<Directory '/var/www/aliases'>" >> /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "Options Indexes FollowSymLinks MultiViews" >> /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "AllowOverride all" >> /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "Order allow,deny" >> /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "allow from all" >> /etc/apache2/mods-available/vhost_alias.conf
#sudo echo "</Directory>" >> /etc/apache2/mods-available/vhost_alias.conf

# enable Apache mod_rewrite
#sudo a2enmod vhost_alias

# enable Apache SSL mod
sudo a2enmod ssl

# set default ssl vhost
sudo a2ensite default-ssl

# Install phpmyadmin silently
#echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/app-pass password" |debconf-set-selections
#echo "phpmyadmin phpmyadmin/app-password-confirm password" | debconf-set-selections
#apt-get -q -y install phpmyadmin

# Set some very lax php.ini settings for local development
upload_max_filesize=100M
post_max_size=100M
max_execution_time=600
max_input_time=600
memory_limit=512M
for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit
do
 sed -i "s/^\($key\).*/\1 $(eval echo = \${$key})/" /etc/php5/apache2/php.ini
done

echo "Updating repositories"
sudo apt-get update

echo "Installing XDebug"
sudo apt-get install -y php5-xdebug php5-xmlrpc

# XDEBUG
echo "
;;;;;;;;;;;;;;;;;;;;;;;;;;
; Added to enable Xdebug ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
; use the following command to find xdebug.so:
; find / -name 'xdebug.so' 2> /dev/null
;;;default used:  zend_extension=\"/usr/lib/php5/20131226/xdebug.so\"
zend_extension=\"/usr/lib/php5/20131226/xdebug.so\"

xdebug.default_enable = 1
;;;xdebug.idekey = "vagrant"
xdebug.remote_autostart = 0
xdebug.remote_log=\"/var/log/xdebug/xdebug.log\"
;;unsure about this setting necessity;;;xdebug.remote_host=10.0.2.2 ; IDE-Environments IP, from vagrant box.

xdebug.remote_connect_back = 1
xdebug.remote_enable = 1
xdebug.remote_handler = \"dbgp\"
xdebug.remote_port = 9000
xdebug.var_display_max_children = 512
xdebug.var_display_max_data = 1024
xdebug.var_display_max_depth = 10
xdebug.idekey = \"PHPSTORM\"" >> /etc/php5/apache2/php.ini

echo "Setting locale correctly"
sudo locale-gen en_GB.UTF-8

echo "Restarting Apache one last time..."
sudo service apache2 restart

echo "Installing dos2unix"
sudo apt-get install -y dos2unix
dos2unix /vagrant/backup.sh
ln -s /vagrant/backup.sh /home/vagrant/backup

#append contents of dotprofile to the vagrant profile
# doesn't work too well. :(
#cat /var/www/dotprofile.append.sh >> /home/vagrant/.profile
#trying only bashrc now
# Sexy Prompt install  (take a look  .bash_prompt refenced from .bashrc)
#(cd /tmp && git clone --depth 1 https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc
cat /var/www/.bash_prompt >> /home/vagrant/.bashrc

#copy gitset.sh to executable area for user
cp /var/www/gitset.sh /usr/local/bin
chown vagrant:vagrant /usr/local/bin/gitset.sh
chmod +x /usr/local/bin/gitset.sh
