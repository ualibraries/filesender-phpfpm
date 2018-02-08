# filesender-phpfpm:1.6
Docker image of filesender running within php-fpm, with nginx listening in front.

## Info
This is the 1.6 production release of filesender, which uses simplesamlphp for authentication. If you need shibboleth authentication, look at the 2.0-beta2 release.

Look at the compose/test directory for a [docker-compose](https://docs.docker.com/compose/overview/) example of how to quickly test filesender with a fake user account.

Quite a few more complex authentication options are available through [simplesamlphp](https://simplesamlphp.org/). Look at it's documentation for more details.
