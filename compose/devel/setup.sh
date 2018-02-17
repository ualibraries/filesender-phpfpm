#!/bin/sh
git clone git@github.com:glbrimhall/filesender.git
cp git.config filesender/.git/config
docker-compose up -d
