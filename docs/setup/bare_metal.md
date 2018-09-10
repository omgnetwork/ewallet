# Bare-metal setup

Get the most juice out of your machine by setting up the eWallet onto your base operating system.

## Step 1: Set up the server

Before we begin, be sure to have the following applications installed and running on your machine.

- [PostgreSQL](https://www.postgresql.org/): PostgreSQL is used for storing most of the data for the eWallet and LocalLedger.
- [ImageMagick](https://www.imagemagick.org/script/index.php): ImageMagick is used for formatting images in the Admin Panel. Tested with version `> 7.0.7-22`.
- [Elixir](http://elixir-lang.github.io/install.html): Elixir is used as the primary language for the server components of the eWallet.
- [Git](https://git-scm.com/): Git is used for downloading and synchronizing codebase with the remote code repository.
- [NodeJS](https://nodejs.org/) Node.js is used for building front-end code for the Admin Panel.
- [Yarn](https://yarnpkg.com/en/docs/install) Yarn is used for managing and install front-end dependencies for the Admin Panel.

If you are on MacOS, you may [install the above dependencies via Homebrew](/docs/setup/macos/brew_install_dependencies.md).

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

Then, install the front-end dependencies:

```bash
$ (cd apps/admin_panel/assets/ && yarn install)
```

_The parentheses above forces the commands to be executed in a subshell, and returns to the current working directory after the execution._

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

Also, you will need to setup the test database so tests can be run:

```bash
$ MIX_ENV=test mix do ecto.create, ecto.migrate
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
$ mix seed

# Option 2b: Run this command to set up the initial data and populate the database with more sample data
$ mix seed --sample
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

Having trouble setting up the eWallet? Check the [Setup Troubleshooting Guide](troubleshooting.md).
