#!/bin/sh

set -x

SETUP_DIR="/opt/template"
SETUP_LOG="$SETUP_DIR/setup.log"

if [ ! -f "$SETUP_LOG" ]; then
   touch $SETUP_LOG
   "/setup.sh"
fi

exec /usr/sbin/php-fpm7.0 -F --fpm-config /etc/php/7.0/fpm/php-fpm.conf
