# End-to-End Testing (E2E)

We offer [acceptance tests](https://github.com/omisego/e2e) written using [Robot Framework](http://robotframework.org/).
These tests rely on initial seeded data which are 2 admins and a base account.

## Environment setup

In order to generate the sample data needed for the tests you will need to run:

`mix seed --test --yes`

`--yes` option allows to skip all prompted confirmations which is ideal when ran on an automation server.

You will need to add a few environment variables before running the seed, check [this file](/docs/setup/env.md#e2e-tests) for more informations
