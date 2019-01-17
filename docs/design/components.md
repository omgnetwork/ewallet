# Components

The eWallet is an umbrella Elixir application containing the following sub-applications:

  - [ewallet_api](/apps/ewallet_api): Sub-application acting as a gateway to the World Wide Web through HTTP-RPC endpoints. These endpoints are used to __interact with the eWallet__. Check the [Swagger spec](/apps/ewallet_api/priv/spec.yaml) for more details.

  - [admin_api](/apps/admin_api): Sub-application acting as a gateway to the World Wide Web through HTTP-RPC endpoints. These endpoints are used to __manage__ the system. Check the [Swagger spec](/apps/admin_api/priv/spec.yaml) for more details.

  - [admin_panel](/apps/admin_panel): Sub-application containing the front-end that allows provider admins, such as staff at the headquarter, to perform system-wide actions such as managing tokens, accounts, API keys, users, and wallets.

  - [ewallet](/apps/ewallet): Sub-application containing the business logic (minting process, transfer of value, etc.).

  - [ewallet_db](/apps/ewallet_db): Sub-application containing all the database schemas and migrations.

  - [local_ledger](/apps/local_ledger): Sub-application containing the business logic.

  - [local_ledger_db](/apps/local_ledger_db): Sub-application containing all the database schemas and migrations.

  - [ewallet_config](/apps/ewallet_config): Sub-application used to handle the settings and application environments.

  - [url_dispatcher](/apps/url_dispatcher): Sub-application dealing with dispatching each HTTP request to the appropriate sub-application.

  - [activity_logger](/apps/activity_logger): Sub-application tracking activities such as inserting, updating, deleting records, etc.

  - [utils](/apps/utils): Sub-application containing utility functions that are not strictly related to the eWallet business logic.

  - [load_tester](/apps/load_tester): Sub-application containing the load test runner and its scripts.

## Sub-applications planned

- `blockchain_gateway`: An interface to the blockchain.
