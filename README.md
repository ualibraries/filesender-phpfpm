# filesender-phpfpm:2.0-beta2
Docker image of filesender running within php-fpm, with nginx listening in front.

## Info
This is the 2.0-beta2 production release of filesender, which can use  simplesamlphp or shibboleth for authentication.

Look at the compose/test directory for a [docker-compose](https://docs.docker.com/compose/overview/) example of how to quickly test filesender with a fake user account.

## SimplesSamlPhp
Quite a few more complex authentication options are available through [simplesamlphp](https://simplesamlphp.org/). Look at it's documentation for more details.

## Shibboleth
Look at the compose/shibboleth directory for a [docker-compose](https://docs.docker.com/compose/overview/) example of how to test filesender with shibboleth using [testshib.org](http://www.testshib.org/). The following config files need modifying, replacing the ip address 150.135.119.0 with your machine's ip address.

Then follow the [REGISTER](http://www.testshib.org/register.html) instructions at testshib.org to registor your shibboleth instance. If all goes well you should be able to authenticate.


