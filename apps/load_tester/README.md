# LoadTester

Run:

```ex
Chaperon.run_load_test(LoadTester.Runner); nil
```

## What I wished Chaperon (or I) could do

- Specify a different output folder
- Output folder resides in the sub-app, not at the umbrella app
- Easier way to inspect the latest session state
- More readable way to process the result rather than `:with_result` option

## Usage

1. Spin up a pair of machines with the eWallet app installed
2. Migrate and seed the target machine, e.g. `ewallet-loadtest-server`, with:

```
$ mix ecto.create
$ mix ecto.migrate
$ E2E_ENABLED=true \
  E2E_TEST_ADMIN_EMAIL=ewallet-loadtesting@omise.co \
  E2E_TEST_ADMIN_PASSWORD=loadtesting \
  mix seed --test --yes
```

3. Run the load test from another server with:

```
$ LOADTEST_TOTAL_REQUESTS=180000 \
  LOADTEST_DURATION_SECONDS=6000 \
  LOADTEST_PROTOCOL=http \
  LOADTEST_HOST=localhost \
  LOADTEST_PORT=4000 \
  LOADTEST_EMAIL=ewallet-loadtesting@omise.co \
  LOADTEST_PASSWORD=loadtesting \
  mix run -e 'Chaperon.run_load_test(LoadTester.Runner)'
```
