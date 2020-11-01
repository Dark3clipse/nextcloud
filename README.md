# nextcloud
My personal nextcloud NAS solution.

## Dependencies

Create an environment with the following dependencies:

- linux environment
- certbot installed with renewal service
- certificates for nextcloud.sophiahadash.nl
- docker and docker-compose installed

## Deploy

Create an environment file:

```
touch .env
nano .env
```

Deploy nextcloud using docker:

```
bash run.sh
```