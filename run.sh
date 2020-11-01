#!/bin/bash

# configure application prior to build
if test -f ".env"; then
  export $(cat .env | xargs)
fi

# test availability of environment variables
if [ -z "$MYSQL_PASSWORD" ]; then echo "Environment variable MYSQL_PASSWORD is unset or empty." && exit 1; fi
if [ -z "$NEXTCLOUD_PATH" ]; then echo "Environment variable NEXTCLOUD_PATH is unset or empty." && exit 1; fi
if [ -z "$BACKUP_PATH" ]; then echo "Environment variable BACKUP_PATH is unset or empty." && exit 1; fi

# define some derivative variables
export MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD
export MYSQL_DATABASE=nextcloud
export MYSQL_USER=nextcloud

# clone rsnapshot-docker
git clone https://github.com/helmuthb/rsnapshot-docker


# deploy
docker-compose --env-file ./.env -f nextcloud.yml -p nextcloud up -d