# Admin Panel

The OmiseGO Wallet admin panel for a provider to manage staff, users, roles and permissions,
API access, tokens, transactions, etc.

## Usage

### Running the Admin Panel

The Admin Panel will be started along with the whole umbrella app.
There are no extra steps required to start the Admin Panel if you started the eWallet server.

### Development

NOTE: if you wish to play around or run the admin panel independently with dev server, follow the instruction below.

You will first need to create the `.env` file located under the project's root directory of the app `./assets/`
with your own keys. `BACKEND_API_URL` is your API server url. `BACKEND_WEBSOCKET_URL` is the Websocket key corresponding to your Admin API.

Example **.env** file
```
BACKEND_API_URL=https://omisego.network/admin/api
BACKEND_WEBSOCKET_URL=https://omisego.network/admin/socket
```