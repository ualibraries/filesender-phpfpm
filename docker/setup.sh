!/bin/bash

set -x

USER='www-data'
USER_ID='33'
GROUP_ID='33'

FILESENDER_SERIES=${FILESENDER_V%%.*}
FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-shibboleth}
FILESENDER_URL=${FILESENDER_URL:-"http://localhost"}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@abcde.edu}
SMTP_SERVER=${SMTP_SERVER:-localhost}

CONF_DIR="/opt/conf"
FILESENDER_DIR="/opt/filesender"
SIMPLESAML_DIR="/opt/simplesamlphp"
SIMPLESAML_MODULES="cas exampleauth"

DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-filesender}
DB_USER=${DB_USER:-filesender}
DB_PASSWORD=${DB_PASSWORD:-filesender}

# Update smtp configuration
SSMTP_CONF=/etc/ssmtp/ssmtp.conf
if [ ! -f "${SSMTP_CONF}.default" ] && [ -f "$SSMTP_CONF" ]; then
  mv "$SSMTP_CONF" "${SSMTP_CONF}.default"
fi

cat <<EOF > /etc/ssmtp/ssmtp.conf
root=$ADMIN_EMAIL
mailhub=$SMTP_SERVER
hostname=localhost
FromLineOverride=yes
UseSTARTTLS=yes
EOF

# simplesaml.php setup:

if [ -f ${CONF_DIR}/simplesamlphp/saml20-idp-remote.php ]; then
   echo "Copying SAML2 remote IdP metadata file..."
   cp ${CONF_DIR}/simplesamlphp20-idp-remote.php ${SIMPLESAML_DIR}/metadata/saml20-idp-remote.php
fi

if [ -f ${CONF_DIR}/simplesamlphp/config.php ]; then
   echo "Copying SAML2 config file..."
   cp ${CONF_DIR}/simplesamlphp/config.php ${SIMPLESAML_DIR}/config/config.php
fi

if [ -f ${CONF_DIR}/simplesamlphp/authsources.php ]; then
   echo "Copying SAML2 authsources file..."
   cp ${CONF_DIR}/simplesamlphp/authsources.php ${SIMPLESAML_DIR}/config/authsources.php
fi

if [ -d ${CONF_DIR}/simplesamlphp/metadata-import ]; then
   echo "Copying SAML2 metadata import directory..."
   cp -r ${CONF_DIR}/simplesamlphp/metadata-import ${SIMPLESAML_DIR}/metadata
fi

if [ -d ${CONF_DIR}/simplesamlphp/cert ]; then
   echo "Copying certificates to SimpleSAMLphp cert dir..."
   cp -r ${CONF_DIR}/simplesamlphp/cert ${SIMPLESAML_DIR}
fi

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

  if [ -f ${CONF_DIR}/filesender/login.php ]; then
      cp ${CONF_DIR}/filesender/login.php ${FILESENDER_DIR}/www/login.php
  fi
    
  mkdir ${FILESENDER_DIR}/log
  ln -s /tmp ${FILESENDER_DIR}/tmp

  MAIL_ATTR=${MAIL_ATTR:-"HTTP_SHIB_MAIL"}
  NAME_ATTR=${NAME_ATTR:-"HTTP_SHIB_CN"}
  UID_ATTR=${UID_ATTR:-"HTTP_SHIB_UID"}
  FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-"shibboleth"}
else
  MAIL_ATTR=${MAIL_ATTR:-"mail"}
  NAME_ATTR=${NAME_ATTR:-"cn"}
  UID_ATTR=${UID_ATTR:-"uid"}
  FILESENDER_AUTHTYPE=${FILESENDER_AUTHTYPE:-"sp-default"}
fi

if [ -f ${CONF_DIR}/filesender/config.php ]; then
    cp ${CONF_DIR}/filesender/config.php ${FILESENDER_DIR}/config/config.php
else 
    cat ${CONF_DIR}/filesender/config-v${FILESENDER_SERIES}.php | \
    sed \
      -e "s|{FILESENDER_URL}|${FILESENDER_URL}|g" \
      -e "s|{FILESENDER_AUTHTYPE}|${FILESENDER_AUTHTYPE}|g" \
      -e "s|{DB_HOST}|${DB_HOST}|g" \
      -e "s|{DB_NAME}|${DB_NAME}|g" \
      -e "s|{DB_USER}|${DB_USER}|g" \
      -e "s|{DB_PASSWORD}|${DB_PASSWORD}|g" \
      -e "s|{ADMIN_USERS}|${ADMIN_USERS:-admin}|g" \
      -e "s|{ADMIN_EMAIL}|${ADMIN_EMAIL}|g" \
      -e "s|{MAIL_ATTR}|${MAIL_ATTR}|g" \
      -e "s|{NAME_ATTR}|${NAME_ATTR}|g" \
      -e "s|{UID_ATTR}|${UID_ATTR}|g" \
    > ${FILESENDER_DIR}/config/config.php
fi


if [ -e /usr/bin/mysql ]; then
  RESULT=`nc -z -w1 ${DB_HOST} 3306 && echo 1 || echo 0`

  while [ $RESULT -ne 1 ]; do
    echo " **** Database is not responding, waiting... **** "
    sleep 5
    RESULT=`nc -z -w1 ${DB_HOST} 3306 && echo 1 || echo 0`
  done

  if [ "$FILESENDER_SERIES" = "1" ]; then
    SQL_FILE=${FILESENDER_DIR}/scripts/mysql_filesender_db.sql

    cat ${CONF_DIR}/filesender/mysql_filesender_db.sql ${SQL_FILE} | \
    sed \
      -e "s|{DB_NAME}|${DB_NAME}|g" \
    > "${SQL_FILE}"

    mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} < ${SQL_FILE}
  else
    php /opt/filesender/scripts/upgrade/database.php      
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
