## Vagrant setup

We recommend using [Goban](https://github.com/omisego/goban), a tool we created to bootstrap a Vagrant environment that resembles production. Goban will generate a consistent development environment within a virtual machine for you without having to install the dependencies manually.

To start using the eWallet server with Vagrant via Goban:

1. Follow the instructions at [omisego/goban](https://github.com/omisego/goban) to setup Goban.
1. Access your virtual machine with `vagrant ssh`
2. Run the tests: `mix test`
3. Seed the initial data with `mix seed`
4. Start the server with `mix omg.server`

Once the application started successfully, you should see the following output:

```elixir
[info] Setting up websockets dispatchers...
[info] Running UrlDispatcher.Plug with Cowboy http on port 4000
```

You can now try access your eWallet server using the available APIs:

```bash
$ curl http://localhost:4000
{"status": true}
```
