#!/bin/sh
git clone git@github.com:glbrimhall/filesender.git
cp git.config filesender/.git/config
cd filesender
git checkout issue-342-fix
cd -
docker-compose up -d
