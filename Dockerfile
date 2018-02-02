FROM uazlibraries/debian-php-fpm:latest

ENV FILESENDER_V=2.0-beta2 SSP_V=1.15.0

RUN \
cd /opt && \
curl -kL https://github.com/filesender/filesender/archive/filesender-$FILESENDER_V.tar.gz | tar xz && \
mv filesender-filesender-$FILESENDER_V filesender && \
curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_V}/simplesamlphp-${SSP_V}.tar.gz | tar xz && \
mv simplesamlphp-${SSP_V} simplesamlphp

ADD docker/* /
ADD conf /opt/conf

RUN chown -R www-data.www-data /opt/*

VOLUME ["/opt/filesender", "/opt/simplesamlphp"]

#RUN apk add --no-cache libmcrypt-dev \
#                       pcre-dev \
#                       ssmtp
#
#RUN docker-php-ext-install pdo_mysql \
#                           mcrypt \
#                           opcache

#ADD www-pool.conf /usr/local/etc/php-fpm.d/www.conf
#ADD docker-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
