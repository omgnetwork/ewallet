# Running the tests

## Unit tests

Before we start the application, let's try running the tests. Create the test databases:

```bash
$ MIX_ENV=test mix do ecto.create, ecto.migrate

# Or if you are using specific database URLs:
$ MIX_ENV=test DATABASE_URL=postgres://localhost/ewallet_test_db LOCAL_LEDGER_DATABASE_URL=postgres://localhost/local_ledger_test_db mix do ecto.create, ecto.migrate
```

Then, let's run the tests:

```bash
$ mix test

# Or if you are using specific database URLs:
$ DATABASE_URL=postgres://localhost/ewallet_test_db LOCAL_LEDGER_DATABASE_URL=postgres://localhost/local_ledger_test_db mix test
```

You should see the results similar to below:

```elixir
==> local_ledger_db
Finished in 0.5 seconds
57 tests, 0 failures

==> ewallet_db
Finished in 2.3 seconds
249 tests, 0 failures

==> local_ledger
Finished in 0.9 seconds
24 tests, 0 failures

==> ewallet
Finished in 3.4 seconds
141 tests, 0 failures

==> admin_api
Finished in 4.4 seconds
184 tests, 0 failures

==> ewallet_api
Finished in 4.5 seconds
134 tests, 0 failures
```

All the tests should pass. If some tests are failing, double-check you have install all the dependencies. If you keep getting the failures, you can get in touch with us on [Gitter](https://gitter.im/omisego/ewallet)!

## Acceptance tests

We offer acceptance tests at [omisego/e2e](https://github.com/omisego/e2e) written using [Robot Framework](http://robotframework.org/).
These tests rely on initial seeded data which are 2 admins and a base account.

Prior to running the acceptance tests, you will need generate the sample data needed for the tests:

```bash
$ mix seed --test --yes
```

`--yes` option allows to skip all prompted confirmations which is ideal when ran on an automation server.

You will need to add a few environment variables before running the seed, check [Environment Variables](/docs/setup/env.md#e2e-tests) for more information.
