#!/bin/bash

# configure application prior to build
if test -f ".env"; then
  export $(cat .env | xargs)
fi

# test availability of environment variables
if [ -z "$MYSQL_PASSWORD" ]; then echo "Environment variable MYSQL_PASSWORD is unset or empty." && exit 1; fi
if [ -z "$NEXTCLOUD_PATH" ]; then echo "Environment variable NEXTCLOUD_PATH is unset or empty." && exit 1; fi
if [ -z "$RECAPTCHA_PUBLIC" ]; then echo "Environment variable RECAPTCHA_PUBLIC is unset or empty." && exit 1; fi
if [ -z "$RECAPTCHA_PRIVATE" ]; then echo "Environment variable RECAPTCHA_PRIVATE is unset or empty." && exit 1; fi
if [ -z "$WHATSAPP_AS" ]; then echo "Environment variable WHATSAPP_AS is unset or empty." && exit 1; fi
if [ -z "$WHATSAPP_HS" ]; then echo "Environment variable WHATSAPP_HS is unset or empty." && exit 1; fi
if [ -z "$WHATSAPP_C" ]; then echo "Environment variable WHATSAPP_C is unset or empty." && exit 1; fi

# define some derivative variables
export MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD
export MYSQL_DATABASE=nextcloud
export MYSQL_USER=nextcloud
export POSTGRES_PASSWORD=$MYSQL_PASSWORD

# insert postgresql password in synapse/homeserver.yaml
sed -i "s/__POSTGRESQL_PASSWORD__/$MYSQL_PASSWORD/g" ./synapse/homeserver.yaml
sed -i "s/__RECAPTCHA_PRIVATE__/$RECAPTCHA_PRIVATE/g" ./synapse/homeserver.yaml
sed -i "s/__RECAPTCHA_PUBLIC__/$RECAPTCHA_PUBLIC/g" ./synapse/homeserver.yaml
sed -i "s/__POSTGRESQL_PASSWORD__/$MYSQL_PASSWORD/g" ./synapse/whatsapp/config.yaml
sed -i "s/__WHATSAPP_AS__/$WHATSAPP_AS/g" ./synapse/whatsapp/config.yaml
sed -i "s/__WHATSAPP_HS__/$WHATSAPP_HS/g" ./synapse/whatsapp/config.yaml
sed -i "s/__WHATSAPP_AS__/$WHATSAPP_AS/g" ./synapse/appservices/whatsapp.yaml
sed -i "s/__WHATSAPP_HS__/$WHATSAPP_HS/g" ./synapse/appservices/whatsapp.yaml
sed -i "s/__WHATSAPP_C__/$WHATSAPP_C/g" ./synapse/appservices/whatsapp.yaml

# clone rsnapshot-docker
if [ ! -d ./rsnapshot-docker ]; then
	git clone https://github.com/helmuthb/rsnapshot-docker
fi

# add crontab
# 0 23 * * * certbot renew --webroot -w /data/letsencrypt

# deploy
docker-compose --env-file ./.env -f nextcloud.yml -p nextcloud up -d