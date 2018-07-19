## Vagrant setup

We recommend using [Goban](https://github.com/omisego/goban), a tool we created to bootstrap a Vagrant environment that resembles production.

Goban generates a consistent development environment within a virtual machine for you without having to install the dependencies manually.

## Step 1: Set up the server

First, follow the instructions at [omisego/goban](https://github.com/omisego/goban) to setup Goban.

Then, run the following command to access your virtual machine:

```bash
$ vagrant ssh
```

Now that you are in your virtual machine, run the following command to setup the databases:

```bash
$ mix do ecto.create, ecto.migrate
```

Then, run the tests to make sure the codebase is healthy:

```
$ mix test
```

## Step 2: Seed the databases

Access your virtual machine with `vagrant ssh` if you have not done so in Step 1.

Some initial data is required to start the server. Either run the seed or the sample seed below:

```bash
# Option 2a: Run this command to set up the initial data
$ mix do ecto.seed

# Option 2b: Run this command to set up the initial data and populate the database with more sample data
$ mix do ecto.seed --sample
```

### Step 3: Start the server

Access your virtual machine with `vagrant ssh` if you have not done so in Step 1 or 2.

Now, from your virtual machine, start the server using the following command:

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
