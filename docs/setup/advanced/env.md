# Environment Variables

## General

Below are the general environment variables needed for the eWallet to run.

- `MIX_ENV`: Environment in which the application is being ran. `prod` for production.
- `PORT`: The port that the application listens on.
- `EWALLET_SECRET_KEY`: Encryption key used to encrypt some data in the database.
- `LOCAL_LEDGER_SECRET_KEY`: Encryption key used to encrypt some data in the database.

To generate a new secret key using Elixir:

```
$ elixir -e "IO.puts 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"
8I_xIED7p7ruxxM1vNiWzsud3DALk0cnpcAncC2YyMs
```

## Database

The eWallet needs access to two different databases: one for the eWallet itself and one for the local ledger. The following environment variables need to be set.

- `DATABASE_URL`
- `LOCAL_LEDGER_DATABASE_URL`

## Error Reporting

The eWallet only supports [Sentry](https://sentry.io/welcome/) for now. You can specify the DSN for it with the following environment variable:

- `SENTRY_DSN`

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
