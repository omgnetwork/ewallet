# Bare-metal setup

Get the juice out of your machine by setting up the eWallet server onto your base operation system.

## Installing the dependencies

Be sure to have the following applications installed and running on your machine.

-   [PostgreSQL](https://www.postgresql.org/): PostgreSQL is used to store most of the data for the eWallet API and local ledger.

-   [ImageMagick](https://www.imagemagick.org/script/index.php): ImageMagick is used to format images in the admin panel. Tested with version `> 7.0.7-22`.

-   [Elixir](http://elixir-lang.github.io/install.html): Elixir is a dynamic, functional language designed for building scalable and maintainable applications.

-   [Git](https://git-scm.com/): Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

## Getting the code

Once you have installed the all the dependencies and they are running, it's time to pull the eWallet code. To do so, let's use `git`:

```
git clone https://github.com/omisego/ewallet && cd ./ewallet
```

Feel free to look around!

## Setting up

We now need to pull the Elixir dependencies:

```
$ mix deps.get
```

Then get the front-end dependencies:

```
$ cd apps/admin_panel/assets/ && yarn install
```

You will need to set some environment variables before proceeding. You can use `export ENV=value` to set environment variables in the current session (or you can add them to whatever profile file you are using).

**It is important to understand that the eWallet actually connects to two different databases. The first one, the local ledger database, is only used to store transactions, making it easier for audits. The second one contains, well, everything else.**

In development, you should only have to set the `DATABASE_URL` and `LOCAL_LEDGER_DATABASE_URL` if your local PostgreSQL installation requires authentication.

-   `DATABASE_URL`: The URL where the main database can be accessed. Defaults to `postgres://localhost/ewallet_dev` in `dev`, `postgres://localhost/ewallet_test` in `test`.
-   `LOCAL_LEDGER_DATABASE_URL`: The URL where the ledger database can be accessed. Defaults to `postgres://localhost/local_ledger_dev` in `dev`, `postgres://localhost/local_ledger_test` in `test`.

The `ewallet_dev` and `local_ledger_dev` don't need to be created beforehand as long as the database URLs contain credentials allowing this kind of operations.

In some cases, you might also want to customize the following ones, depending on your development setup:

-   `BASE_URL`: The URL where the application can be accessed. Defaults to `http://localhost:4000`.
-   `PORT`: The internal listening port for the application. Default to `4000`.

To learn more about all the environment variables available for production deployments (or if you want to get fancy in local), checkout [this doc](/docs/setup/env.md).

## Migrating the development database

If all the tests passed, we can create the development databases:

```
$ mix do ecto.create, ecto.migrate
```

## Inserting some data

Everything is in place and we can now run the seeds to populate the eWallet database with some initial data:

```
$ mix seed
```

**Note: The command above seeds the minimum amount of data to get the environment up and running. To play in development environment with some sample data, run `mix seed --sample` instead.**

## Booting up

Time to start the application!

```
$ mix omg.server
```

Navigate to `http://localhost:4000/api/client` in your browser and you should see the following `JSON` representation popping up:

```
{
  "success": true,
  "services": {
    "local_ledger": true,
    "ewallet": true
  }
}
```

You can also access the Admin Panel web interface via `http://localhost:4000/api/admin` using the credentials provided during the seed.
