#!/bin/bash
# This script is based off of ideas from https://github.com/litnet/docker-filesender/blob/master/web/docker-entrypoint.sh

set -x

USER='www-data'
USER_ID='33'
GROUP_ID='33'

FILESENDER_SERIES=${FILESENDER_V%%.*}
FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-shibboleth}
FILESENDER_URL=${FILESENDER_URL:-"http://localhost"}
FILESENDER_LOGOUT_URL=${FILESENDER_LOGOUT_URL:-"$FILESENDER_URL/login.php"}
FILESENDER_STORAGE=${FILESENDER_STORAGE:-"Filesystem"}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@abcde.edu}
SMTP_SERVER=${SMTP_SERVER:-localhost}

TEMPLATE_DIR="/opt/template"
FILESENDER_DIR="/opt/filesender"
SIMPLESAML_DIR="/opt/simplesamlphp"
SIMPLESAML_MODULES="cas exampleauth"

DB_HOST=${DB_HOST:-localhost}
DB_TYPE=${DB_TYPE:-mysql}
DB_NAME=${DB_NAME:-filesender}
DB_USER=${DB_USER:-filesender}
DB_PASSWORD=${DB_PASSWORD:-filesender}

if [ "$DB_TYPE" = "mysql" ]; then
  # default port for mysql
  DB_PORT=${DB_PORT:-3306}
else
  # default port for postgresql
  DB_PORT=${DB_PORT:-5432}
fi

function sed_file {
  if [ "$2" = "" ]; then
    SRCFILE="$1.default"
    DSTFILE="$1"
    if [ ! -f "$SRCFILE" ]; then
      cp "$1" "$SRCFILE"
    fi
  else
    SRCFILE="$1"
    DSTFILE="$2"
  fi

  cat "$SRCFILE" | sed \
    -e "s|{FILESENDER_URL}|${FILESENDER_URL}|g" \
    -e "s|{FILESENDER_LOGOUT_URL}|${FILESENDER_LOGOUT_URL}|g" \
    -e "s|{FILESENDER_STORAGE}|${FILESENDER_STORAGE}|g" \
    -e "s|{FILESENDER_AUTHTYPE}|${FILESENDER_AUTHTYPE}|g" \
    -e "s|{FILESENDER_AUTHSAML}|${FILESENDER_AUTHSAML}|g" \
    -e "s|{DB_HOST}|${DB_HOST}|g" \
    -e "s|{DB_PORT}|${DB_PORT}|g" \
    -e "s|{DB_TYPE}|${DB_TYPE}|g" \
    -e "s|{DB_NAME}|${DB_NAME}|g" \
    -e "s|{DB_USER}|${DB_USER}|g" \
    -e "s|{DB_PASSWORD}|${DB_PASSWORD}|g" \
    -e "s|{ADMIN_USERS}|${ADMIN_USERS:-admin}|g" \
    -e "s|{ADMIN_EMAIL}|${ADMIN_EMAIL}|g" \
    -e "s|{ADMIN_PSWD}|${ADMIN_PSWD}|g" \
    -e "s|{SIMPLESAML_SALT}|${SIMPLESAML_SALT}|g" \
    -e "s|'123'|\'${ADMIN_PSWD}\'|g" \
    -e "s|'defaultsecretsalt'|\'${SIMPLESAML_SALT}\'|g" \
    -e "s|{MAIL_ATTR}|${MAIL_ATTR}|g" \
    -e "s|{NAME_ATTR}|${NAME_ATTR}|g" \
    -e "s|{UID_ATTR}|${UID_ATTR}|g" \
   > "$DSTFILE"
}

# php-fpm setup
if [ "$PHP_FPM_LISTEN" != "" ]; then
  sed -i -e "s|^listen = /run/php/.*|listen = $PHP_FPM_LISTEN|g" \
      /etc/php/7.0/fpm/pool.d/www.conf
fi

# ssmtp setup
SSMTP_CONF=/etc/ssmtp/ssmtp.conf
if [ ! -f "${SSMTP_CONF}.default" ] && [ -f "$SSMTP_CONF" ]; then
  mv "$SSMTP_CONF" "${SSMTP_CONF}.default"
fi

cat <<EOF > $SSMTP_CONF
root=$ADMIN_EMAIL
mailhub=$SMTP_SERVER
FromLineOverride=yes
EOF

if [ "$SMTP_TLS" != "" ]; then
  echo "UseTLS=yes" >> $SSMTP_CONF
  echo "UseSTARTTLS=yes" >> $SSMTP_CONF
fi
if [ "$SMTP_USER" != "" ]; then
  echo "AuthUser=$SMTP_USER" >> $SSMTP_CONF
fi
if [ "$SMTP_PSWD" != "" ]; then
  echo "AuthPass=$SMTP_PSWD" >> $SSMTP_CONF
  echo "AuthMethod=LOGIN" >> $SSMTP_CONF
fi

# simplesaml.php setup:

if [ "$SIMPLESAML_SALT" = "" ]; then
  SIMPLESAML_SALT=`tr -c -d '0123456789abcdefghijklmnopqrstuvwxyz' </dev/urandom | dd bs=32 count=1 2>/dev/null;echo`
fi

sed_file "${SIMPLESAML_DIR}/config/config.php"
sed_file "${SIMPLESAML_DIR}/config/authsources.php"

for MODULE in $SIMPLESAML_MODULES; do
  if [ -d ${SIMPLESAML_DIR}/modules/$MODULE ]; then
    touch ${SIMPLESAML_DIR}/modules/$MODULE/enable
  fi
done         

# filesender setup:

# Create /data directory to store filesender uploaded files
mkdir /data
chown -R $USER.$USER /data

if [ "$FILESENDER_SERIES" = "2" ]; then
  if [ -f ${TEMPLATE_DIR}/filesender/login.php ]; then
    cp ${TEMPLATE_DIR}/filesender/login.php ${FILESENDER_DIR}/www/login.php
  fi
    
  mkdir ${FILESENDER_DIR}/log
  ln -s /tmp ${FILESENDER_DIR}/tmp

  FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-"shibboleth"}
else
  FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-"sp-default"}
fi

if [ "$FILESENDER_AUTHTYPE" = "shibboleth" ]; then
  # Attributes passed via environment variables from shibboleth
  MAIL_ATTR=${MAIL_ATTR:-"HTTP_SHIB_MAIL"}
  NAME_ATTR=${NAME_ATTR:-"HTTP_SHIB_CN"}
  UID_ATTR=${UID_ATTR:-"HTTP_SHIB_UID"}
else
if [ "$FILESENDER_AUTHTYPE" = "fake" ]; then
  # Manually set attribute values for v2.0 "fake authentication"
  MAIL_ATTR=${MAIL_ATTR:-"fakeuser@abcde.edu"}
  NAME_ATTR=${NAME_ATTR:-"Fake User"}
  UID_ATTR=${UID_ATTR:-"fakeuser"}
else
  # Attributes passed from simplesamlphp
  FILESENDER_AUTHSAML=${FILESENDER_AUTHSAML:-"sp-default"}
  MAIL_ATTR=${MAIL_ATTR:-"mail"}
  NAME_ATTR=${NAME_ATTR:-"cn"}
  UID_ATTR=${UID_ATTR:-"uid"}
fi
fi

if [ -f ${TEMPLATE_DIR}/filesender/config.php ]; then
  cp ${TEMPLATE_DIR}/filesender/config.php ${FILESENDER_DIR}/config/config.php
else 
  sed_file ${TEMPLATE_DIR}/filesender/config-v${FILESENDER_SERIES}.php ${FILESENDER_DIR}/config/config.php
fi

# setup database
if [ "`which nc`" != "" ]; then
  RESULT=`nc -z -w1 ${DB_HOST} ${DB_PORT} && echo 1 || echo 0`

  while [ $RESULT -ne 1 ]; do
    echo " **** Database is not responding, waiting... **** "
    sleep 5
    RESULT=`nc -z -w1 ${DB_HOST} ${DB_PORT} && echo 1 || echo 0`
  done

  if [ "$FILESENDER_SERIES" = "1" ]; then
    SQL_FILE=${FILESENDER_DIR}/scripts/mysql_filesender_db.sql

    sed_file ${TEMPLATE_DIR}/filesender/mysql_filesender_db.sql "${SQL_FILE}"

    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} < ${SQL_FILE}
  else
    php /opt/filesender/scripts/upgrade/database.php

    if [ "xx$SELENIUM_HOST" != "xx" ]; then
      export PGPASSWORD=$DB_PASSWORD
      psql -c 'create database filesenderdataset;' -h $DB_HOST -U $DB_USER
      bzcat /opt/filesender/scripts/dataset/dumps/filesender-2.0beta1.pg.bz2 | psql -h $DB_HOST -U $DB_USER -d filesenderdataset
    fi
  fi
fi

chown -R www-data.www-data /opt/*

# Check if www-data's uid:gid has been requested to be changed
NEW_UID=${CHOWN_WWW%%:*}
NEW_GID=${CHOWN_WWW##*:}

if [ "$NEW_GID" = "" ]; then
  NEW_GID=$NEW_UID
fi

if [ "$NEW_UID" != "" ]; then
  # Change old $USER_ID to $NEW_UID, similarly old $GROUP_ID->$NEW_GID
  groupmod -g $NEW_GID $USER
  usermod -u $NEW_UID $USER
  find / -type d -path /proc -prune -o -group $GROUP_ID -exec chgrp -h $USER {} \;
  find / -type d -path /proc -prune -o -user $USER_ID -exec chown -h $USER {} \;
fi
