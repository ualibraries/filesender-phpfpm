FROM uazlibraries/nginx-shibboleth

# Change www-data uid:gid from 33:33 to archivematica's 333:333
RUN groupmod -g 1000 www-data && usermod -u 1000 www-data
