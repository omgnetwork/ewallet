# Docker setup

You can setup the eWallet server using either Docker Compose or roll your own Docker environment with our pre-built Docker image.

## Option 1: Quick start with Docker Compose

Prerequisite: You will need [Docker](https://www.docker.com/get-docker) and [Docker Compose](https://docs.docker.com/compose/install/) installed.

Create your own `docker-compose.yml` file using the following script:

```yaml
version: '2.1'
services:
  ewallet:
    image: omisego/ewallet:latest
    depends_on:
      db:
        condition: service_healthy
    environment:
    - DATABASE_URL=postgresql://postgres:password@db:5432/ewallet
    - LOCAL_LEDGER_DATABASE_URL=postgresql://postgres:password@db:5432/local_ledger
    - MIX_ENV=dev
    - ENV=dev
    ports:
    - 4000:4000

  db:
    image: postgres:9
    restart: always
    environment:
      POSTGRES_PASSWORD: password
    ports:
    - 5432:5432
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      retries: 3
```

Then run the following command to provision the images:

```bash
$ docker-compose up
```

Many thanks to suprtux1 for this awesome and simple docker-compose.yml file.

## Option 2: Using the pre-built Docker image

We provides a Docker image for quick installation at the [omisego/ewallet](https://hub.docker.com/r/omisego/ewallet/) repository on Docker Hub with the following tags:

-   `latest` tracks current (i.e. develop branch)
-   `stable` tracks stable (i.e. master branch)

Additionally, all commits in develop and master branches are also built. It is highly recommended to pin the version to specific commit in anything that resembles production environment. An easiest way to get the Docker image running would be (assuming [PostgreSQL](https://hub.docker.com/_/postgres/) is already setup):

```
$ docker run \
    -e DATABASE_URL="postgresql://postgres@127.0.0.1:5432/ewallet" \
    -e LOCAL_LEDGER_DATABASE_URL="postgresql://postgres@127.0.0.1:5432/local_ledger" \
    -p 4000:4000 \
    omisego/ewallet:latest
```

Then run `docker exec <container-id> mix do ecto.create, ecto.migrate` to setup the database.
