# Install Basic
apt update
apt upgrade -y
apt dist-upgrade -y
apt install build-essential bzr zip htop curl unzip openssh-server mysql-client net-tools -y
apt autoremove -y

# Get Server IP
serverip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

# Change Date / Time
timedatectl set-timezone America/Lima

#Install Apache2
apt install -y apache2 apache2-utils
mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
cp templates/apache /etc/apache2/apache2.conf
sed "s/USERNAME/$serverip/g" templates/apache > /etc/apache2/apache2.conf
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod rewrite
a2enmod headers
a2enmod setenvif
a2enmod deflate
a2enmod expires
a2enmod filter
a2enmod mime
mv /var/www/html/index.html /var/www/html/sisope_$(date +%s).html
touch /var/www/html/index.html
service apache2 restart

#Install PHP
apt install php php-dev php-mysql php-mbstring libapache2-mod-php php-curl php-gd php-zip php-pdo php-tokenizer php-json php-imagick php-xml php-bcmath php-intl php-readline php-memcached php-pcov php-xdebug  -y
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
mv /etc/php/8.1/apache2/php.ini /etc/php/8.1/apache2/php.ini.bak
mv /etc/php/8.1/cli/php.ini /etc/php/8.1/cli/php.ini.bak
cp templates/php /etc/php/8.1/apache2/php.ini
cp templates/php /etc/php/8.1/cli/php.ini
service apache2 restart

#Configure Mod Security
apt install libapache2-mod-security2 -y
sudo a2enmod security2
sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
sudo git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /etc/apache2/modsecurity-crs
cd /etc/apache2/modsecurity-crs
sudo mv crs-setup.conf.example crs-setup.conf
sudo echo "<IfModule mod_security2>
    <FilesMatch \.php$>
        SecRuleEngine On
        SecRuleRemoveById 960010
        IncludeOptional /etc/apache2/modsecurity-crs/*.conf
    </FilesMatch>
</IfModule>" | sudo tee /etc/apache2/mods-available/modsecurity-php.conf
sudo service apache2 restart

ufw --force enable
ufw allow "Apache Full"
ufw allow OpenSSH

echo "AllowTcpForwarding NO" >> /etc/sshd_config
echo "ClientAliveCountMax 2" >> /etc/sshd_config
echo "LogLevel VERBOSE" >> /etc/sshd_config
echo "MaxAuthTries 3" >> /etc/sshd_config
echo "MaxSessions 2" >> /etc/sshd_config
echo "TCPKeepAlive NO" >> /etc/sshd_config
echo "X11Forwarding NO" >> /etc/sshd_config
echo "AllowAgentForwarding NO" >> /etc/sshd_config

sudo service ssh restart