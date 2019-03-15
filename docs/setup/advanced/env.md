# Environment Variables

## General

Below are the general environment variables needed for the eWallet to run.

- `MIX_ENV`: The environment in which the application is being ran. `prod` for production.
- `PORT`: The port that the application listens on.
- `EWALLET_SECRET_KEY`: The encryption key used to encrypt data in the `ewallet` database.
- `LOCAL_LEDGER_SECRET_KEY`: The encryption key used to encrypt data in the `local_ledger` database.

To generate a new secret key using Elixir:

```
$ elixir -e "IO.puts 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"
8I_xIED7p7ruxxM1vNiWzsud3DALk0cnpcAncC2YyMs
```

## Database

The eWallet needs access to two different databases: one for the eWallet itself and one for the local ledger. The following environment variables need to be set.

- `DATABASE_URL`: The connection URI for the `ewallet` database.
- `LOCAL_LEDGER_DATABASE_URL`: The connection URI for the `local_ledger` database.
- `EWALLET_POOL_SIZE`: The connection pool size for the `ewallet` database. _Defaults to `10`._
- `LOCAL_LEDGER_POOL_SIZE`: The connection pool size for the `local_ledger` database. _Defaults to `10`._

See the connection URI format at [Postgres' Connection URIs](https://www.postgresql.org/docs/current/libpq-connect.html#id-1.7.3.8.3.6).

See the suggestion for finding the optimal pool size at [How to Find the Optimal Database Connection Pool Size](https://wiki.postgresql.org/wiki/Number_Of_Database_Connections#How_to_Find_the_Optimal_Database_Connection_Pool_Size)

## Application Monitoring

The eWallet supports [AppSignal](https://appsignal.com/) for application monitoring. To enable AppSignal, configure the following environment variable:

- `APPSIGNAL_PUSH_API_KEY`: The AppSignal's Push API key for your application.
For example, `APPSIGNAL_PUSH_API_KEY=00000000-0000-0000-0000-000000000000`

Monitoring is automatically enabled when the above environment variable is configured.

## Error Reporting

The eWallet only supports [Sentry](https://sentry.io/welcome/) for now. You can specify the DSN for it with the following environment variable:

- `SENTRY_DSN`: The Sentry's Data Source Name for your project.
  For example, `SENTRY_DSN=https://public_key@host:port/1`

### Local File Storage

Nothing else to set, files will be stored at the root of the project in `public/uploads/`.

### E2E Tests

- `E2E_ENABLED`: Allows to run `mix seed --test --yes` to generate test data
- `E2E_TEST_ADMIN_EMAIL`: The email of the first test admin
- `E2E_TEST_ADMIN_PASSWORD`: The password of the first test admin
- `E2E_TEST_ADMIN_1_EMAIL`: The email of the second test admin
- `E2E_TEST_ADMIN_1_PASSWORD`: The password of the second test admin
- `E2E_TEST_USER_EMAIL`: The email of the test user (non-admin)
- `E2E_TEST_USER_PASSWORD`: The password of the test user (non-admin)
