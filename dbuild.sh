#!/bin/bash
set -x

NETWORK=host

TAG=${4:-latest}
CONTAINER=${3:-filsender-test}
REPOSITORY=${2:-filesender-phpfpm}
ACTION=${1}
DAEMONIZE=-d

# Delete test container built from docker file
docker stop $CONTAINER
docker rm $CONTAINER

if [ "$ACTION" = "BUILD" ]; then
# Delete test image built from docker file
#docker image rm $REPOSITORY:$TAG

# Create test image from docker file
docker build -t $REPOSITORY:$TAG .

ACTION=DEBUG

fi

if [ "$ACTION" = "DEBUG" ]; then
    DAEMONIZE=""
    DEBUG="--user root -it --entrypoint /bin/bash"
fi

docker run $DAEMONIZE $DEBUG \
       --net=$NETWORK \
       --tmpfs /var/log/php-fpm:uid=33,gid=33,mode=755,noexec,nodev,nosuid \
       --tmpfs /run/lock:uid=0,gid=0,mode=1777,noexec,nodev \
       --tmpfs /run/php:uid=33,gid=33,mode=775,noexec,nodev,nosuid \
       --name $CONTAINER \
       $REPOSITORY:$TAG
