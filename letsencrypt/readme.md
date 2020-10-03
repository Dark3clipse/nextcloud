# Letsencrypt automation

This setup is able to issue certificates for several tuneblendr.com (sub)domains and implements automatic renewal using docker.


## Usage

To fetch initial certificates run the following command. Additional domains can be added in the docker-compose file.
```
docker-compose -f issue.yml -p letsencrypt up
```

To manually attempt to renew all existing certificates that are due for renewal run:
```
docker-compose -f renew.yml -p letsencrypt up
```

To automatically renew certificates add a crontab on a Docker Swarm manager node using `sudo crontab -e`:
```
0 23 * * * docker-compose -f /home/shadash/buildserver/letsencrypt/renew.yml -p letsencrypt up && docker service update buildserver_nginx --force && docker service update buildserver_registry --force
```
This crontab executes every 24h and restarts services that use the certificates.


## Dependencies

* This requires an existing GlusterFS volume named `letsencrypt` and the GlusterFS plugin for docker.