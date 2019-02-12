This is link of another guide -> http://debabhishek.com/writes/Installing-and-Running-TextSecure-Signal-Server-on-Windows/

Signal Server Installation Guide
======================
Author: Aqnouch Mohammed aqnouch.mohammed@gmail.com

## Abstract
This paper is a quickstart for anyone aims to setup a working Signal Server.

## What Is Signal
Signal is an encrypted instant messaging and voice calling application for Android. It uses the Internet to send one-to-one and group messages, which can include images and video messages, and make one-to-one voice calls. Signal uses standard phone numbers as identifiers and end-to-end encryption to secure all communications to other Signal users.


## Installation Steps
The main server source code could be found here:

    https://github.com/signalapp/Signal-Server

Before starting working let's clonned the source code:

	https://github.com/signalapp/Signal-Server.git
	
Inter the project folder:

	cd Signal-server
	
Build the main server server jar
	
	mvn install -DskipTests	
	

## Prerequisites
To be sure to have the latest version of the programmes.

	sudo apt-get update 


### Install Java
	sudo add-apt-repository -y ppa:webupd8team/java
	sudo apt-get update 
	sudo apt-get install -y oracle-java8-installer
	sudo apt-get install -y oracle-java8-unlimited-jce-policy 

### Install Redis
	sudo apt-get install -y redis-server

### Install database

	sudo apt-get install postgresql postgresql-contrib -y


Create postgres root user:

	sudo -i -u postgres
	createdb accountdb
	createdb messagedb 
	
	createuser --interactive
	psql
	ALTER USER "Signal" WITH PASSWORD 'Signal!!';

##Remotely access to the postgresql database
To open the port 5432 edit your /etc/postgresql/9.*/main/postgresql.conf and change

    listen_addresses='localhost'
    
To

    listen_addresses='*'
    
Edit

    /etc/postgresql/9.*/main/pg_hba.conf
    
And add

    host all all * md5
    
And restart or restart you DBMS

    invoke-rc.d postgresql restart







### The configuration files
Here a working server file filled with **fake** values. You have to provide your own values:

	twilio: # Twilio gateway configuration
	  accountId: AC0a435e5bc49AC0a435e5bc49AC0a435v
	  accountToken: bdc211b8a91990988166a82a65f0aafv
	  numbers: [+10133273922]
	  messagingServicesId: 
	  localDomain: akdev.tech

	push:
	  queueSize: # Size of push pending queue

	turn: # TURN server configuration
	  secret: test
	  uris: ["turn:127.0.0.1:3478"]

	cache:
	  url: http://127.0.0.1:6379

	directory:
	  url: http://127.0.0.1:6379

	messageStore: # Postgresql database configuration for message store
	  driverClass: org.postgresql.Driver
	  user: Signal
	  password: Signal!!
	  url: jdbc:postgresql://akdev.tech:5432/messagedb

	attachments: # AWS S3 configuration
	  accessKey: AKIAIHGXT3LQBZVVMH5A
	  accessSecret: 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
	  bucket: Signal

	profiles: # AWS S3 configuration
	  accessKey: AKIQBZVVMH5QAIHGXT3A
	  accessSecret: TAA2Wy1mGRiHzOCCMlB8TVu7zOiNX2OR/JmzvWSx
	  bucket: Signal
	  region: eu-west-1

	database: # Postgresql database configuration
	  driverClass: org.postgresql.Driver
	  user: Signal
	  password: Signal!!
	  url: jdbc:postgresql://akdev.tech:5432/accountdb

	apn:
	  bundleId: com.nevermynd.messenger
	  pushCertificate: config/certs/Certificates.p12
	  pushKey: aqnouch

	gcm:
	  senderId: 90077701463
	  apiKey: AIzaSyAHNIwGE0yKG9QnDZQMcziNAF-0zliXOtH

	server:
	  applicationConnectors:
	    - type: http
	      port: 8080
	  adminConnectors:
	    - type: http
	      port: 8081
	      
###  Database migration
Once you have PostresSQL Up&Running with username, password, messagesdb and accountsdb (two db can be the same one) **and** these parameters are well coded inside TSS' yml  file as seen above as jdbc string , you can now create data structures needed by the application.

	java -jar ../jars/Signal-2.1.jar  messagedb migrate  ../config/Signal.yml
	java -jar ../jars/Signal-2.1.jar  accountdb migrate  ../config/Signal.yml


### S3 configuration
create S3 bucket
an IAM user, and add it to the S3FullAccess group



### Reverse proxy
	
	sudo a2enmod proxy proxy_http proxy_wstunnel

The configuration to add the the site availible section in: apache /etc/apache2/sites-available/

<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerAdmin aqnouch.mohammed@gmail.com
	ServerName kalam.app

        DocumentRoot /var/www/kalam/

        <Directory /var/www/tkalam>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>	

	SSLCertificateFile /etc/letsencrypt/live/kalam.app/fullchain.pem
	SSLCertificateKeyFile /etc/letsencrypt/live/kalam.app/privkey.pem
	Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>



### Turn server installation
	sudo apt-get install -y coturn
	sudo apt-get install -y build-essential
	sudo turnserver -a -o -v -n  --no-dtls --no-tls -u test:test -r "someRealm"

### SSL Certificate

Create the ssl certificate

	sudo add-apt-repository ppa:certbot/certbot -y
	sudo apt-get update -y
	sudo apt-get install python-certbot-apache  -y
    sudo certbot --authenticator standalone --installer apache -d <yourdomain> --pre-hook "systemctl stop apache2" --post-hook "systemctl start apache2"
    
All feedbacks are welcome    

### Extra help

I do freelance work, so if you want extra help, we can discuss it over the mail: aqnouch.mohammed@gmail.com