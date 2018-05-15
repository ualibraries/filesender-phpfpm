#!/bin/sh
git clone git@github.com:glbrimhall/filesender.git
cp git.config filesender/.git/config
cd filesender
git checkout directory-tree-upload
cd -
docker-compose up -d
