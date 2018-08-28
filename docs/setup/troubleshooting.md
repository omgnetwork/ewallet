# Setup Troubleshooting Guide

Below is the list the solutions to common issues experienced by our community while setting up the eWallet.

## Issue: "invalid url ..., path should be a database name"

```elixir
(Mix) Could not start application ewallet_db: EWalletDB.Application.start(:normal, []) returned an error: shutdown: failed to start child: EWalletDB.Repo
(EXIT) an exception was raised: (Ecto.InvalidURLError) invalid url http://localhost, path should be a database name
```

**Suggestion:**

The eWallet is unable to connect to the database. Make sure that you are using a valid database URL. A valid database URL should consist of the database protocol, e.g. `postgres://` and should point to the address where your database resides, as well as the database name. For example:

```bash
export DATABASE_URL=postgres://localhost/ewallet_dev
export LOCAL_LEDGER_DATABASE_URL=postgres://localhost/local_ledger_dev
```

The above set valid URLs to the environment variables, which point the eWallet to the `postgres` databases at `localhost` with the database names `ewallet_dev` and `local_ledger_dev`.

## Issue: "Connect raised a KeyError error. The exception details are hidden ..."

```elixir
(Mix) The database for LocalLedgerDB.Repo couldn't be created: an exception was raised:
** (RuntimeError) Connect raised a KeyError error. The exception details are hidden, as they may contain sensitive data such as database credentials.
    (elixir) lib/keyword.ex:386: Keyword.fetch!/2
    (postgrex) lib/postgrex/protocol.ex:610: Postgrex.Protocol.auth_md5/4
    (postgrex) lib/postgrex/protocol.ex:504: Postgrex.Protocol.handshake/2
    (db_connection) lib/db_connection/connection.ex:135: DBConnection.Connection.connect/2
    (connection) lib/connection.ex:622: Connection.enter_connect/5
    (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
```

**Suggestion:**

Your eWallet instance have reached the database server, but the database server is expecting a username and password. Make sure that:

1. You are not running commands as `sudo`.

2. If your database server requires authentication, you have provided the eWallet with the correct postgres's username and password, e.g. (notice the your_pg_username:your_pg_password part)

```bash
export DATABASE_URL=postgres://your_pg_username:your_pg_password@localhost/ewallet_dev
export LOCAL_LEDGER_DATABASE_URL=postgres://your_pg_username:your_pg_password@localhost/local_ledger_dev
```

3. If you prefer to entrust your local connections, your `pg_hba.conf` file should allow trusted connections from localhost like below:

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
```
