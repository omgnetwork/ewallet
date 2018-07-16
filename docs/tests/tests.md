# Running the tests

## Unit tests

Before we start the application, let's try running the tests. Create the test databases:

```
$ MIX_ENV=test mix do ecto.create, ecto.migrate
```

Or if you're using specific database URLs:

```
$ MIX_ENV=test DATABASE_URL=postgres://localhost/ewallet_test_db LOCAL_LEDGER_DATABASE_URL=postgres://localhost/local_ledger_test_db mix do ecto.create, ecto.migrate
```

**If you don't want to do that, you can always search & replace the default values in the config files, but only do that in development to give it a try - we really don't recommend changing the code that way for production setups.**

Then, let's run the tests:

```
$ mix test
```

Or:

```
$ DATABASE_URL=postgres://localhost/ewallet_test_db LOCAL_LEDGER_DATABASE_URL=postgres://localhost/local_ledger_test_db mix test
```

```
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

Check [this file](/docs/tests/e2e.md) for all informations about acceptance tests.
