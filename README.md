# filesender-phpfpm:2.0-beta2 #
[TOC]
# Info
# Dependencies
# Environment Variables
# simplesamlphp
# shibboleth

## Info ##
Docker image of filesender running within php-fpm, with nginx listening in front.

This is the 2.0-beta2 production release of filesender, which can use  simplesamlphp or shibboleth for authentication.

## Dependencies ##
Filesender requires the following environment dependencies:
1. An smtp server to send emails. For the examples located in the compose/ directory, they use a gmail test account. For a production deployment an organization's smtp server should be used.
* If using shibboleth authentication instead of simplesamlphp, a public IP address to send saml payloads to, ie not one of the [private IPs](https://en.wikipedia.org/wiki/Private_network) beginning with 10.x, 172.x, or 192.168.x. If the docker image is running on a private IP behind a router NAT, it might be possible for the router to forward the saml payloads through https to the private IP as long as the router has been given a public IP. For production deployments, a ssl cert associated with a public DNS entry is the ideal situation.
* For production deployments, planned disk capacity to store uploaded files.

## Environment Variables ##

The following environment variables control the docker setup:

* FILESENDER_URL - full URL to enter in the browser to bring up filesender
* FILESENDER_AUTHTYPE - unused by the 1.x series, for 2.x series, use the values:
** shibboleth - use shibboleth for authentication
** saml - use simplesamlphp for authentication
** fake - use a fake user. The MAIL_ATTR, NAME_ATTR, UID_ATTR specify the values to use.
* FILESENDER_AUTHSAML - when using simplesaml for authentication, which is the only option with the 1.x series, the authentication type to use as defined in simplesamlphps's [config/authsources.php](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml/simplesamlphp/config) file.
* MAIL_ATTR, NAME_ATTR, UID_ATTR - depending on the value of FILESENDER_AUTHTYPE:
** shibboleth - the fastcgi environment variable containing the attribute value.
** simplesamlphp - the saml attribute name to use.
** fake - the actual value to use
* DB_HOST - the database hostname to connect to.
* DB_NAME - the database namespace to install filesender tables into
* DB_USER - the database user to connecto the database system with
* DB_PASSWORD - the database user password
* SMTP_SERVER - the SMTP server to send email through. It must be a valid server for filesender to work.
* SMTP_TLS - The SMTP server requires TLS encrypted communication
* SMTP_USER - the optional user account needed to connect to the SMTP server
* SMTP_PSWD - the optional SMTP user account password 
* ADMIN_EMAIL - email address of the filesender admin account, must be valid
* ADMIN_USERS - the set of user accounts that should be considered administrators
* ADMIN_PSWD - the password to use for the admin account 
* SIMPLESAML_MODULES - the space seperated list of simplesaml [module directories](https://github.com/simplesamlphp/simplesamlphp/tree/master/modules) to enable for authentication and filtering. Usually enabling one of these modules requires setting configuration settings for it in the authsources.php file.
* SIMPLESAML_SALT - an optional simplesaml salt value to use. A value will get auto-generated on first time startup if missing.

## simplesamlphp ##
Look at the [compose/simplesaml](https://github.com/ualibraries/filesender-phpfpm/tree/master/compose) directory for a [docker-compose](https://docs.docker.com/compose/overview/) example of how to quickly setup filesender with a fake user account using simplesamlphp.

```sh

cd compose/simplesaml
docker-compose up

browse to <http://localhost>

```

Quite a few more complex authentication options are available through [simplesamlphp](https://simplesamlphp.org/). Look at it's documentation for more details. In each case the authsources.php file will likely need to get modified and a module enabled through setting the SIMPLESAML_MODULES environment variable. More complex examples that would require certificates should have docker mounting to the /opt/simplesamlphp/config/ directory so the certs, config.php, and authsources.php are properly setup.

## shibboleth ##
Look at the compose/shibboleth directory for a [docker-compose](https://docs.docker.com/compose/overview/) example of how to test filesender with shibboleth using [testshib.org](http://www.testshib.org/). The following config files need modifying, replacing the ip address 150.135.119.0 with your machine's ip address.

Then follow the [REGISTER](http://www.testshib.org/register.html) instructions at testshib.org to registor your shibboleth instance. If all goes well you should be able to authenticate.


