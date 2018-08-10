# Docker setup

You can setup the eWallet server using either Docker Compose or roll your own Docker environment with our pre-built Docker image.

## Step 1: Set up the server

### 1a: Quick start with Docker Compose

_Prerequisite: You will need [Docker](https://www.docker.com/get-docker) and [Docker Compose](https://docs.docker.com/compose/install/) installed._

First, generate secret keys for eWallet and LocalLedger by running:

```
$ elixir -e "IO.puts 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"
```

Then, create your `docker-compose.yml` file using the following script:

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
    image: omisego/ewallet:latest
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

networks:
  external:
  internal:

volumes:
  postgres-db:
```

Then, run the following command to provision the images:

```bash
$ docker-compose up
```

Then, run the following command to setup the databases:

```bash
$ docker exec <container-id> mix do ecto.create, ecto.migrate
```

### 1b: Using the pre-built Docker image

Alternatively, to get the Docker image running without docker-compose would be (assuming [PostgreSQL](https://hub.docker.com/_/postgres/) is already setup):

```bash
# Pulls the omisego/ewallet image from https://hub.docker.com/r/omisego/ewallet/
$ docker run \
    -e DATABASE_URL="postgresql://postgres@127.0.0.1:5432/ewallet" \
    -e LOCAL_LEDGER_DATABASE_URL="postgresql://postgres@127.0.0.1:5432/local_ledger" \
    -p 4000:4000 \
    omisego/ewallet:latest
```

While the command above pulls the latest image, *it is highly recommended to pin the version to specific commit in anything that resembles a production environment.*

Then, run the following command to setup the database:

```bash
$ docker exec <container-id> mix do ecto.create, ecto.migrate
```

## Step 2: Seed the databases

Some initial data is required to start the server. Either run the seed or the sample seed below:

```bash
# Option 2a: Run this command to set up the initial data
$ docker exec -it <container-id> mix seed

# Option 2b: Run this command to set up the initial data and populate the database with more sample data
$ docker exec -it <container-id> mix seed --sample
```

## Step 3: Start the server

Start the server using the following command:

```bash
$ docker exec <container-id> mix omg.server
```

You should see the following output:

```elixir
[info] Setting up websockets dispatchers...
[info] Running UrlDispatcher.Plug with Cowboy http on port 4000
```

You can now access your eWallet server using the available APIs:

```bash
$ curl http://localhost:4000
{"status": true}
```

### Next step

Read the [Documentation](/README.md/#documentation) to learn more and start using your eWallet!
