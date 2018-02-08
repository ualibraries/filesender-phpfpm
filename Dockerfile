FROM uazlibraries/debian-php-fpm:latest

ENV FILESENDER_V=1.6 SSP_V=1.15.0

RUN \
cd /opt && \
curl -kL https://github.com/filesender/filesender/archive/filesender-$FILESENDER_V.tar.gz | tar xz && \
mv filesender-filesender-$FILESENDER_V filesender && \
curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_V}/simplesamlphp-${SSP_V}.tar.gz | tar xz && \
mv simplesamlphp-${SSP_V} simplesamlphp

# Add filesender and simplesamlphp configuration to /opt/conf
ADD conf /opt/conf

# Ensure correct runtime permissions - php-fpm runs as www-data
RUN chown -R www-data.www-data /opt/*

# Change php-fpm to listen on a unix socket
RUN \
sed -i -e 's|^listen|;listen|g' /etc/php/7.0/fpm/pool.d/zz-docker.conf && \
sed -i \
 -e 's|^listen = 127|;listen = 127|g' \
sed -i -e 's|^;listen = /|listen = /|g' /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e 's|^;listen.o = /|listen.o = /|g' /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e 's|^;listen.g = /|listen.g = /|g' /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e 's|^;listen.m = /|listen.m = /|g' /etc/php/7.0/fpm/pool.d/www.conf

# Add setup and startup config files to /
ADD docker/* /

VOLUME ["/opt/filesender", "/opt/simplesamlphp"]

ENTRYPOINT ["/entrypoint.sh"]
