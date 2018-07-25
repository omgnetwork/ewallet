# Bare-metal setup

Get the most juice out of your machine by setting up the eWallet server onto your base operating system.

## Step 1: Set up the server

Before we begin, be sure to have the following applications installed and running on your machine.

- [PostgreSQL](https://www.postgresql.org/): PostgreSQL is used to store most of the data for the eWallet API and local ledger.
- [ImageMagick](https://www.imagemagick.org/script/index.php): ImageMagick is used to format images in the admin panel. Tested with version `> 7.0.7-22`.
- [Elixir](http://elixir-lang.github.io/install.html): Elixir is a dynamic, functional language designed for building scalable and maintainable applications.
- [Git](https://git-scm.com/): Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.
- [NodeJS](https://nodejs.org/) Node.js is a JavaScript runtime built on Chrome's V8 JavaScript engine. Uses for admin panel building package and dependencies installation.

Now that you have the applications installed, proceed with 1.1 through 1.5 to setup the server.

### 1.1 Get the code

Pull the eWallet code from our Git repository to a directory of your choice:

```bash
$ git clone https://github.com/omisego/ewallet && cd ./ewallet
```

### 1.2 Install code dependencies

Fetch the Elixir dependencies:

```bash
$ mix deps.get
```

Then, fetch the front-end dependencies:

```bash
$ (cd apps/admin_panel/assets/ && yarn install)
```

### 1.3 Configure environment variables

Many configurations have default values pre-defined. If your environment requires different values, run `export ENV=value` to set environment variables in the current session (or add them to whatever profile file you are using).

Environment variable | Description
-------------------- | -----------
`BASE_URL` | The URL where the application can be accessed. <br /> _Defaults to `http://localhost:4000`_
`PORT` | The internal listening port for the application <br /> _Defaults to `4000`_
`DATABASE_URL` | The URL where the eWallet database can be accessed. <br /> _Defaults to `postgres://localhost/ewallet_dev`_
`LOCAL_LEDGER_DATABASE_URL` | The URL where the LocalLedger database can be accessed. <br /> _Defaults to `postgres://localhost/local_ledger_dev`_

Learn more about all the environment variables available at [Environment Variables](/docs/setup/advanced/env.md).

### 1.4 Migrate the databases

Run the following command to setup the databases:

```bash
$ mix do ecto.create, ecto.migrate
```

### 1.5 Run the tests

Run the tests to make sure that your setup is healthy:

```
$ mix test
```

## Step 2: Seed the database

Some initial data is required to start the server. Either run the seed or the sample seed below:

```bash
# Option 2a: Run this command to set up the initial data
$ mix do ecto.seed

# Option 2b: Run this command to set up the initial data and populate the database with more sample data
$ mix do ecto.seed --sample
```

### Step 3: Start the server

Start the server using the following command:

```bash
$ mix omg.server
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
