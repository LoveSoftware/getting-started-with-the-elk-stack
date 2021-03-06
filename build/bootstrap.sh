
### ELK Stack

# Update Apt
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' | sudo tee /etc/apt/sources.list.d/elasticsearch.list
echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' | sudo tee /etc/apt/sources.list.d/logstash.list
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update

#Required for test script
sudo apt-get install -y curl zip

# Install codebase
cd
wget https://github.com/LoveSoftware/getting-started-with-the-elk-stack/archive/01-tutorial.zip
unzip -q 01-tutorial.zip
mv getting-started-with-the-elk-stack-01-tutorial code

# Install Java
sudo echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
sudo apt-get install -y oracle-java8-installer
sudo apt-get install -y oracle-java8-set-default

# Install Elastic Search
sudo apt-get -y install elasticsearch=1.4.4
sudo update-rc.d elasticsearch defaults 95 10
sudo cp ~/code/build/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
sudo service elasticsearch start
sudo /usr/share/elasticsearch/bin/plugin -install royrusso/elasticsearch-HQ

#Install Kibana
cd ~; wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
tar xf kibana-4.0.1-linux-x64.tar.gz
sudo mv kibana-4.0.1-linux-x64 /opt/kibana4.0.1

# Hosts File
echo '127.0.0.1 elastic.logstashdemo.com' | sudo tee --append /etc/hosts
echo '127.0.0.1 kibana.logstashdemo.com' | sudo tee --append /etc/hosts
echo '127.0.0.1 logs.logstashdemo.com' | sudo tee --append /etc/hosts
echo '127.0.0.1 web.logstashdemo.com' | sudo tee --append /etc/hosts

# Install logstash
sudo apt-get install logstash
sudo update-rc.d logstash defaults 95 10

#Import geo database
cd /etc/logstash
sudo curl -O "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
sudo gunzip GeoLiteCity.dat.gz
cd

# Create SSL Certs
sudo mkdir -p /etc/pki/tls/certs
sudo mkdir /etc/pki/tls/private
sudo cp ~/code/build/artifacts/logstash-forwarder.crt /etc/pki/tls/certs
sudo cp ~/code/build/artifacts/logstash-forwarder.key /etc/pki/tls/private
sudo service logstash restart

#### WEBAPP

# NGINX
sudo apt-get install -y nginx
sudo apt-get install -y apache2-utils
sudo rm /etc/nginx/sites-enabled/default
sudo cp ~/code/build/nginx/logdemo.conf /etc/nginx/sites-available/logdemo.conf
sudo ln -s /etc/nginx/sites-available/logdemo.conf /etc/nginx/sites-enabled/logdemo.conf
sudo service nginx restart

# Install Required packages
sudo apt-get install -y git
sudo apt-get install -y php5-fpm php5 php5-dev
sudo apt-get install -y varnish

# Configure Varnish
sudo cp ~/code/build/varnish/varnish /etc/default/varnish
sudo cp ~/code/build/varnish/default.vcl /etc/varnish/default.vcl
sudo service varnish restart

# Configure Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

cd ~/code
composer install

# Add log files
sudo touch /var/log/logstash-forwarder.log
sudo touch /var/log/app.log
sudo touch /var/log/bus.log
sudo chown www-data /var/log/app.log
sudo chown www-data /var/log/bus.log
sudo chmod 777 /var/log/logstash-forwarder.log

# Configure The Logstash Forwarder
sudo cp ~/code/build/logstash/logstash-forwarder /usr/bin/logstash-forwarder
sudo chmod +x /usr/bin/logstash-forwarder

sudo mkdir -p /etc/pki/tls/certs
sudo cp ~/code/build/artifacts/logstash-forwarder.crt /etc/pki/tls/certs/

# Start supervisor to run kibana / logstash forwarder
sudo apt-get install -y supervisor
sudo cp ~/code/build/supervisord/supervisord.conf /etc/supervisor/supervisord.conf
sudo service supervisor restart
