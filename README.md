# filesender-phpfpm:1.6 #

## Info ##
[Docker](https://www.docker.com/what-docker) image of [filesender](http://filesender.org/) running within [php-fpm](https://php-fpm.org/), with [nginx](https://www.nginx.com/) providing the webserver in front. All of the docker images are based off of [Debian](https://www.debian.org/) stable.

This [release of filesender](https://github.com/filesender/filesender) can use [simplesamlphp](https://simplesamlphp.org/) for authentication.

## Dependencies ##
This docker image of filesender requires the following environment dependencies:
1. [docker-compose](https://docs.docker.com/compose/overview/) is installed on the system.
2. An smtp server to send emails. For the examples located in the [compose/](https://github.com/ualibraries/filesender-phpfpm/tree/2.0-beta2/compose) directory, they use a gmail test account. For a production deployment an organization's smtp server should be used.
3. If using shibboleth authentication instead of simplesamlphp, a public IP address for the remote shibboleth-idp to send responses back to the local shibboleth-sp through nginx. If the docker image is running on a [private IP](https://en.wikipedia.org/wiki/Private_network) behind a router NAT, it might be possible for the router to forward the shibboleth-idp responses through https to the private IP as long as the router has been given a public IP. For production deployments, a ssl cert associated with a public DNS entry is the ideal situation.
4. For production deployments, planned disk capacity to store uploaded files.

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
Look at the [compose/simplesaml](https://github.com/ualibraries/filesender-phpfpm/tree/1.6/compose/simplesaml) directory for a [docker-compose](https://github.com/ualibraries/filesender-phpfpm/blob/1.6/compose/simplesaml/docker-compose.yml) example of how to quickly setup filesender with a fake user account using simplesamlphp.

```

cd compose/simplesaml
docker-compose up

```

Then browse to [http://localhost](http://localhost)

Quite a few more complex authentication options are available through [simplesamlphp](https://simplesamlphp.org/docs/stable/simplesamlphp-idp). Look at it's documentation for more details. In each case the authsources.php file will likely need to get modified and a module enabled through setting the SIMPLESAML_MODULES environment variable. More complex examples that would require certificates should have docker mounting to the /opt/simplesamlphp/config/ directory so the certs, config.php, and authsources.php are properly setup.

