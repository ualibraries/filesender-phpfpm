FROM uazlibraries/debian-php-fpm:latest

ENV FILESENDER_V=2.0-beta3 SSP_V=1.15.0 FILESENDER_BRANCH=StorageFilesystemPreserveName

RUN \
cd /opt && \
git clone --verbose -b ${FILESENDER_BRANCH} https://github.com/glbrimhall/filesender.git && \
curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_V}/simplesamlphp-${SSP_V}.tar.gz | tar xz && \
mv simplesamlphp-${SSP_V} simplesamlphp

# Add filesender and simplesamlphp configuration to /opt/conf
ADD template /opt/template

# Ensure correct runtime permissions - php-fpm runs as www-data
RUN chown -R www-data.www-data /opt/*

# Add setup and startup config files to /
ADD docker/* /

VOLUME ["/opt/filesender", "/opt/simplesamlphp"]

CMD ["/entrypoint.sh"]
