FROM uazlibraries/debian-php-fpm:debian9-php-fpm7.0

ENV FILESENDER_V=2.0-issue-342-fix FILESENDER_GIT=https://github.com/glbrimhall/filesender.git SSP_V=1.14.2

RUN \
cd /opt && \
git clone -b ${FILESENDER_V#*-} ${FILESENDER_GIT} && \
curl -L https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_V}/simplesamlphp-${SSP_V}.tar.gz | tar xz && \
mv simplesamlphp-${SSP_V} simplesamlphp && \
cp -fv simplesamlphp/config-templates/* simplesamlphp/config

# Add filesender and simplesamlphp configuration to /opt/conf
ADD template /opt/template

# Ensure correct runtime permissions - php-fpm runs as www-data
RUN chown -R www-data.www-data /opt/*

# Add setup and startup config files to /
ADD docker/* /

VOLUME ["/opt/filesender", "/opt/simplesamlphp"]

CMD ["/entrypoint.sh"]
