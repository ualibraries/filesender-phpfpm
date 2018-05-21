FROM uazlibraries/filesender-phpfpm:devel

# Make apt-get commands temporarily non-interactive
# Solution from https://github.com/phusion/baseimage-docker/issues/58
# Update apt cache to use fastest local mirror
RUN \
export DEBIAN_FRONTEND=noninteractive && \
export DEBCONF_NONINTERACTIVE_SEEN=true && \
apt-get update && \
apt-get install -y php-xdebug && \
apt-get clean

# Install php composer dependencies
RUN cd /opt/filesender && composer update
