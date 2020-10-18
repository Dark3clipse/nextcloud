#!/bin/bash

# configure application prior to build
if test -f ".env"; then
  export $(cat .env | xargs)
fi

# test availability of environment variables
if [ -z "$MYSQL_PASSWORD" ]; then echo "Environment variable MYSQL_PASSWORD is unset or empty." && exit 1; fi
if [ -z "$NEXTCLOUD_PATH" ]; then echo "Environment variable NEXTCLOUD_PATH is unset or empty." && exit 1; fi
if [ -z "$NEXTCLOUD_PATH" ]; then echo "Environment variable BACKUP_PATH is unset or empty." && exit 1; fi
if [ -z "$SYNAPSE_POSTGRESS_PASSWORD" ]; then echo "Environment variable SYNAPSE_POSTGRESS_PASSWORD is unset or empty." && exit 1; fi
if [ -z "$SYNAPSE_KEY_REG" ]; then echo "Environment variable SYNAPSE_KEY_REG is unset or empty." && exit 1; fi
if [ -z "$SYNAPSE_KEY_MACARON" ]; then echo "Environment variable SYNAPSE_KEY_MACARON is unset or empty." && exit 1; fi
if [ -z "$SYNAPSE_KEY_FORM" ]; then echo "Environment variable SYNAPSE_KEY_FORM is unset or empty." && exit 1; fi
if [ -z "$SYNAPSE_KEY_SIGNING" ]; then echo "Environment variable SYNAPSE_KEY_SIGNING is unset or empty." && exit 1; fi
if [ -z "$DISCORD_CLIENT_ID" ]; then echo "Environment variable DISCORD_CLIENT_ID is unset or empty." && exit 1; fi
if [ -z "$DISCORD_BOT_TOKEN" ]; then echo "Environment variable DISCORD_BOT_TOKEN is unset or empty." && exit 1; fi

# define some derivative variables
export MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD
export MYSQL_DATABASE=nextcloud
export MYSQL_USER=nextcloud

# clone rsnapshot-docker
git clone https://github.com/helmuthb/rsnapshot-docker

git clone https://github.com/Half-Shot/matrix-appservice-discord
mv matrix-appservice-discord ./synapse/discord/src


# generate synapse default config
#docker run -it --rm \
#    --mount type=bind,src=$NEXTCLOUD_PATH/synapse,target=/data \
#    -e SYNAPSE_SERVER_NAME=synapse.sophiahadash.nl \
#    -e SYNAPSE_REPORT_STATS=yes \
#    matrixdotorg/synapse:3af9bb7198c64c6e6001b96cbfadc0bc2123d318-multiarch generate
sed -i "s#__SYNAPSE_POSTGRESS_PASSWORD__#$SYNAPSE_POSTGRESS_PASSWORD#g" ./synapse/homeserver.yaml
sed -i "s#__SYNAPSE_KEY_REG__#$SYNAPSE_KEY_REG#g" ./synapse/homeserver.yaml
sed -i "s#__SYNAPSE_KEY_MACARON__#$SYNAPSE_KEY_MACARON#g" ./synapse/homeserver.yaml
sed -i "s#__SYNAPSE_KEY_FORM__#$SYNAPSE_KEY_FORM#g" ./synapse/homeserver.yaml
sed -i "s#__SYNAPSE_KEY_SIGNING__#$SYNAPSE_KEY_SIGNING#g" ./synapse/synapse.sophiahadash.nl.signing.key
sed -i "s#__SYNAPSE_POSTGRESS_PASSWORD__#$SYNAPSE_POSTGRESS_PASSWORD#g" ./synapse/whatsapp/config.yaml
sed -i "s#__DISCORD_CLIENT_ID__#$DISCORD_CLIENT_ID#g" ./synapse/discord/config.yaml
sed -i "s#__DISCORD_BOT_TOKEN__#$DISCORD_BOT_TOKEN#g" ./synapse/discord/config.yaml


# generate synapse bridge registrations
cp ./synapse/whatsapp/config.yaml $NEXTCLOUD_PATH/mautrix-whatsapp/config.yaml
docker run --rm -v $NEXTCLOUD_PATH/mautrix-whatsapp:/data:z dock.mau.dev/tulir/mautrix-whatsapp:latest
chmod -R 777 $NEXTCLOUD_PATH/mautrix-whatsapp/registration.yaml

# deploy
docker-compose --env-file ./.env -f nextcloud.yml -p letsencrypt up -d

# create cron-job entries
croncmd="docker exec -u www-data nextcloud:fpm php -f /var/www/html/cron.php"
cronjob="*/5 * * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

croncmd="docker-compose -f /home/shadash/nextcloud/letsencrypt/renew.yml -p letsencrypt up && docker-compose -f /home/shadash/nextcloud.yml -p letsencrypt up -d"
cronjob="0 23 * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

# create whatsapp database for synapse
docker exec postgres psql -U synapse -c "create database whatsapp"