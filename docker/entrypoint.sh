#!/bin/sh

set -x

SETUP_DIR="/opt/conf/"
SETUP_LOG="$SETUP_DIR/setup.log"

if [ ! -f "$SETUP_LOG" ]; then
   touch $SETUP_LOG
   "/setup.sh"
   #"/setup.sh" > $SETUP_LOG 2>&1
fi

exec /usr/sbin/php-fpm7.0 -F --fpm-config /etc/php/7.0/fpm/php-fpm.conf
