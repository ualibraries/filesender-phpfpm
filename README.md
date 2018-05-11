# filesender-phpfpm:devel #

- [Introduction](#introduction)
- [Dependencies](#dependencies)
- [Environment Variables](#environment-variables)
- [Deployment](#deployment)
  - [simplesamlphp](#simplesamlphp)
  - [shibboleth](#shibboleth)

## Introduction
[Docker](https://www.docker.com/what-docker) image of [filesender](http://filesender.org/) running within [php-fpm](https://php-fpm.org/), with [nginx](https://www.nginx.com/) providing the webserver in front. All of the docker images are based off of [debian](https://www.debian.org/) stable.

This [release](https://github.com/filesender/filesender) of filesender can use [simplesamlphp](https://simplesamlphp.org/) or [shibboleth-sp](https://www.shibboleth.net/products/service-provider) for authentication. Questions directly related on using or configuring filesender should get posted to it's [mailinglist](https://sympa.uninett.no/lists/filesender.org/lists).

## Dependencies
This docker image of filesender requires the following environment dependencies:

### Host system dependencies
1. [docker-compose](https://docs.docker.com/compose/overview/) is installed on the system.
2. The host system's time synchronized with a master [ntp](https://en.wikipedia.org/wiki/Network_Time_Protocol) server.
3. No other service on the system is listening at port 80 or 443. This can be changed through modifying the docker-compose configuration and files.
4. A public IP address if using shibboleth authentication. For production deployments, having nginx using an ssl cert associated with a public DNS entry is the ideal situation.
5. For production deployments, planned disk capacity to store uploaded files.

### External dependencies

1. An [smtp](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) server to send emails. For the examples located in the [compose/](https://github.com/ualibraries/filesender-phpfpm/tree/2.0-beta2/compose) directory, they use a gmail test account. For a production deployment an organization's smtp server should be used.

## Environment Variables

The following environment variables control the docker setup:

* FILESENDER_URL - full URL to enter in the browser to bring up filesender
* FILESENDER_AUTHTYPE - used by the 2.x series with the possible values:
  * shibboleth - use shibboleth for authentication
  * saml - use simplesamlphp for authentication
  * fake - use a fake user to authenticate.
* FILESENDER_AUTHSAML - when using simplesaml for authentication, which is the only option with the 1.x series, the authentication type to use as defined in simplesamlphps's [config/authsources.php](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml/simplesamlphp/config) file.
* MAIL_ATTR, NAME_ATTR, UID_ATTR - depending on the value of FILESENDER_AUTHTYPE:
  * shibboleth - the fastcgi environment variable containing the attribute value.
  * simplesamlphp - the saml attribute name to use.
  * fake - the actual value to use
* DB_TYPE - the database type to use, allowed values are pgsql and mysql. Defaults to mysql.
* DB_HOST - the database hostname to connect to.
* DB_PORT - the database port to connect to. Defaults to 3306 for mysql, 5432 for pgsql
* DB_NAME - the database namespace to install filesender tables into
* DB_USER - the database user to connecto the database system with
* DB_PASSWORD - the database user password
* PHP_FPM_LISTEN - the php-fpm fastcgi listener. Default is to create a unix socket at /run/php/php7.0-fpm.sock. To enable a tcpip listener at port 9000, use the value: 9000
* SMTP_SERVER - the SMTP server to send email through. It must be a valid server for filesender to work.
* SMTP_TLS - The SMTP server requires TLS encrypted communication
* SMTP_USER - the optional user account needed to connect to the SMTP server
* SMTP_PSWD - the optional SMTP user account password
* CHOWN_WWW - An optional uid:gid value for filesender to run as. It is most relevent when docker mounting the container's /data directory to store uploads on the host filesystem. Filesender should be running as the user owning the host system directory, otherwise upload permission errors will occur.
* ADMIN_EMAIL - email address of the filesender admin account, must be valid
* ADMIN_USERS - the set of user accounts that should be considered administrators
* ADMIN_PSWD - the password to use for the admin account 
* SIMPLESAML_MODULES - the space seperated list of simplesaml [module directories](https://github.com/simplesamlphp/simplesamlphp/tree/master/modules) to enable for authentication and filtering. Usually enabling one of these modules requires setting configuration settings for it in the [authsources.php](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml/simplesamlphp/config) file.
* SIMPLESAML_SALT - an optional simplesaml salt value to use. A value will get auto-generated on first time startup if missing.

These variables are set using the [setup.sh](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta2/docker/setup.sh) script, which runs in the filesender-phpfpm docker container the first time it starts up from the location /setup.sh.

## Deployment

### simplesamlphp
To test out filesender using simplesamlphp authentication, run the following commands:

```
	
	git clone -b devel https://github.com/ualibraries/filesender-phpfpm.git
	cd filesender-phpfpm/compose/simplesaml
	docker-compose up
	
```

Then browse to [http://localhost](http://localhost)

To cleanup the above test instance, run:

```
	
	git clone -b devel https://github.com/ualibraries/filesender-phpfpm.git
	cd filesender-phpfpm/compose/simplesaml
	docker-compose rm -fsv
	docker volume prune  # Enter y
	
```

Look at the [compose/simplesaml](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml) directory for a [docker-compose](https://github.com/ualibraries/filesender-phpfpm/blob/1.6/compose/simplesaml/docker-compose.yml) example of how to quickly setup filesender with a fake user account using simplesamlphp.

Three docker containers will be created, validate by running **docker ps -a**

* simplesaml_web_1 - contains nginx
* simplesaml_fpm_1 - contains filesender running under fpm. Any [docker mount](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) of simplesamlphp configuration should get mounted to this container under /opt/simplesamlphp/config. External storage disk capacity should get [docker mounted](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) into the container at /data
* simplesaml_db-host_1 - contains mysql database used by filesender.

Quite a few more complex authentication options are available through [simplesamlphp](https://simplesamlphp.org/docs/stable/simplesamlphp-idp). Look at it's documentation for more details. In each case the [authsources.php](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml/simplesamlphp/config) file will likely need to get modified and a module enabled through setting the SIMPLESAML_MODULES environment variable. More complex examples that would require certificates should have 
[docker mount](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) the /opt/simplesamlphp/config/ directory so the certs, config.php, and authsources.php are properly setup.

AAA### shibboleth
To test out filesender using shibboleth authentication, run the following commands:

```
	
	git clone -b devel https://github.com/ualibraries/filesender-phpfpm.git
	cd filesender-phpfpm/compose/shibboleth
	./setup-shib.sh
	
```

Closely follow the directions given at the end of running *./setup-shib.sh*, following the REGISTER and FINALLY tagged instructions in order.

To cleanup the above test instance, run:

```
	
	git clone -b devel https://github.com/ualibraries/filesender-phpfpm.git
	cd filesender-phpfpm/compose/shibboleth
	docker-compose rm -fsv
	docker volume prune  # Enter y
	
```

Look at the [compose/shibboleth](https://github.com/ualibraries/filesender-phpfpm/tree/2.0-beta2/compose/shibboleth) directory for a [docker-compose](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta2/compose/shibboleth/template/docker-compose.yml) example of how to quickly setup filesender using shibboleth for authentication, using the following instructions. As previously mentioned, a public IP address or a valid DNS name pointing to a public IP address is needed to setup filesender with shibboleth.

Four docker containers will be created, validate by running **docker ps -a**

* shibboleth_web_1 - contains nginx
* shibboleth_fpm_1 - contains filesender running under fpm. External storage disk capacity should get [docker mounted](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) into the container at /data
* shibboleth_shib_1 - contains the shibboleth-sp instance. Any [docker mount](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) of shibboleth configuration should get mounted to this container under /etc/shibboleth
* shibboleth_db-host_1 - contains mysql database used by filesender.

If you have a DNS name pointing to a public IP, run:

[./setup-shib.sh](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta3/compose/shibboleth/setup-shib.sh) *dns_name*

Otherwise, just run in the shell

[./setup-shib.sh](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta3/compose/shibboleth/setup-shib.sh)

It will attempt to auto-calculate your public IP address.

After running, follow the instructions [./setup-shib.sh](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta3/compose/shibboleth/setup-shib.sh) gives to [REGISTER](http://www.testshib.org/register.html) your shibboleth instance at testshib.org.

Finally, browse to the URL given at the end of [./setup-shib.sh](https://github.com/ualibraries/filesender-phpfpm/blob/2.0-beta3/compose/shibboleth/setup-shib.sh)

A public IP address is needed for the remote shibboleth-idp to send responses back to the local shibboleth-sp through nginx. If the docker image is running on a [private IP](https://en.wikipedia.org/wiki/Private_network) behind a router NAT, it is possible for the router to forward the shibboleth-idp responses through https to the private IP as long as the router has been given a public IP.

For production deployments, most organizations using shibboleth have a sample /etc/shibboleth/ that needs just a few configuration tweaks to connect the local shibboleth-sp docker image to the organization's shibboleth-idp. This tweaked /etc/shibboleth directory should be [docker mounted](https://docs.docker.com/storage/bind-mounts/#choosing-the--v-or-mount-flag) into the shibboleth-sp docker container.

Note the organization's /etc/shibboleth/shibboleth2.xml must have the following code block in it to correctly resource protect with nginx's fastcgi implementation of shibboleth-sp:

```xml
	
	<RequestMapper type="XML">
	  <RequestMap>
	  <Host name="<change to your public ip or dns name>"
	      authType="shibboleth"
	      requireSession="true"
	      redirectToSSL="443">
	    <Path name="/index.php"/>
	    <Path name="/rest.php"/>
	  </Host>
	  </RequestMap>
	</RequestMapper>
	
```
