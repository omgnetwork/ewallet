# Components

The eWallet is an umbrella Elixir application containing the following sub-applications:

  - [ewallet_api](/apps/ewallet_api): Sub-application acting as a gateway to the World Wide Web through HTTP-RPC endpoints. These endpoints are used to __interact with the eWallet__. Check the [Swagger spec](/apps/ewallet_api/swagger-doc.yaml) for more details.

  - [admin_api](/apps/admin_api): Sub-application acting as a gateway to the World Wide Web through HTTP-RPC endpoints. These endpoints are used to __manage__ the system. Check the [Swagger spec](/apps/admin_api/swagger-doc.yaml) for more details.

  - [admin_panel](/apps/admin_panel): Sub-application containing the front-end that allows provider admins, such as staff at the headquarter, to perform system-wide actions such as managing tokens, accounts, API keys, users, and wallets.

  - [ewallet](/apps/ewallet): Sub-application containing the business logic (minting process, transfer of value, etc.).

  - [ewallet_db](/apps/ewallet_db): Sub-application containing all the database schemas and migrations.

  - [local_ledger](/apps/local_ledger): Sub-application containing the business logic.

  - [local_ledger_db](/apps/local_ledger_db): Sub-application containing all the database schemas and migrations.

  - [url_dispatcher](/apps/url_dispatcher): Sub-application dealing with dispatching each HTTP request to the appropriate sub-application.

## Sub-applications planned

- `request_logger`: A logging system allowing developers to debug an eWallet.
- `blockchain_gateway`: An interface to the blockchain.
