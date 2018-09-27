# Docker setup

You can setup the eWallet server using either 1) Docker Compose or 2) roll your own Docker environment with our pre-built Docker image.

## Option 1: Using Docker Compose

Install [Docker](https://www.docker.com/get-docker) and [Docker Compose](https://docs.docker.com/compose/install/).

Then, create your `docker-compose.yml` file using the following script.

```yaml
version: "3"
services:
  postgres:
    image: postgres:9.6.9-alpine
    restart: always
    volumes:
      - postgres-db:/var/lib/postgresql/data
    networks:
      - internal
    environment:
      POSTGRESQL_PASSWORD: passw0rd
    healthcheck:
      test: ["CMD-SHELL", "pg_isready", "-U", "postgres"]
      interval: 30s
      retries: 3

  mailhog:
    image: mailhog/mailhog:v1.0.0
    restart: always
    networks:
      - internal

  ewallet:
    container_name: docker-local-ewallet
    image: omisego/ewallet:v1.0.0
    restart: always
    networks:
      - internal
      - external
    depends_on:
      - postgres
    environment:
      DATABASE_URL: "postgresql://postgres:passw0rd@postgres:5432/ewallet"
      LOCAL_LEDGER_DATABASE_URL: "postgresql://postgres:passw0rd@postgres:5432/local_ledger"
      EWALLET_SECRET_KEY: "<ewallet_secret_key_here>"
      LOCAL_LEDGER_SECRET_KEY: "<local_ledger_secret_key_here>"
      SMTP_HOST: mailhog
      SMTP_PORT: 1025
    ports:
      - 4000:4000

networks:
  external:
  internal:

volumes:
  postgres-db:
```

Notice that the values for `EWALLET_SECRET_KEY` and `LOCAL_LEDGER_SECRET_KEY` are missing. Replace the values with your own generated ones. We recommend that you generate a different secret key for each. The commands below will generate the keys and replace them automatically:

```
$ sed -i -e "s/<ewallet_secret_key_here>/$(openssl rand -base64 32 | sed 's/\//\\\//g')/" docker-compose.yml
$ sed -i -e "s/<local_ledger_secret_key_here>/$(openssl rand -base64 32 | sed 's/\//\\\//g')/" docker-compose.yml
```

Once the `EWALLET_SECRET_KEY` and `LOCAL_LEDGER_SECRET_KEY` are replaced, run the following command to create and start the containers:

```bash
$ docker-compose up -d
```

The eWallet should now be running in the background. If you see database errors, this is normal. Create and seed the database using the command below:

```bash
$ docker exec -it docker-local-ewallet env MIX_ENV=prod mix do local.hex --force, local.rebar --force, ecto.create, ecto.migrate, seed --sample
```

You should now be able to access your eWallet server using the available APIs:

```bash
$ curl http://localhost:4000
{"status": true}
```

## Option 2: Using pre-built Docker image

To get the Docker image running without docker-compose would be (assuming [PostgreSQL](https://hub.docker.com/_/postgres/) is already setup):

```bash
# Pulls the omisego/ewallet image from https://hub.docker.com/r/omisego/ewallet/
$ docker run \
    --name docker-local-ewallet \
    -e DATABASE_URL="postgresql://postgres@127.0.0.1:5432/ewallet" \
    -e LOCAL_LEDGER_DATABASE_URL="postgresql://postgres@127.0.0.1:5432/local_ledger" \
    -p 4000:4000 \
    omisego/ewallet:v1.0.0
```

The command above pulls and starts an eWallet server with the v1.0.0 image. If you wish, you can pick [other available tags from the Docker Hub](https://hub.docker.com/r/omisego/ewallet/tags/).

Now run the following command to setup and seed the database:

```bash
$ docker exec -it docker-local-ewallet \
  env MIX_ENV=prod mix do \
  local.hex --force, local.rebar --force, \
  ecto.create, ecto.migrate, \
  seed --sample
```

You should now be able to access your eWallet server using the available APIs:

```bash
$ curl http://localhost:4000
{"status": true}
```

## Next step

Read the [Documentation](/README.md/#documentation) to learn more and start using your eWallet!

Having trouble setting up the eWallet? Check the [Setup Troubleshooting Guide](troubleshooting.md).
