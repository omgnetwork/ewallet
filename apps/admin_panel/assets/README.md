# Admin Panel

The OmiseGO Wallet admin panel for a provider to manage staff, users, roles and permissions,
API access, tokens, transactions, etc.

## Usage

### Development

1. You will first need to create the `.env` file located under the project's root directory of the app `./assets/` with your own keys. There are 2 keys that is needed to be able to run and connect to the server `BACKEND_API_URL` and `BACKEND_WEBSOCKET_URL`

Example **.env** file
```
BACKEND_API_URL=https://omisego.network/admin/api
BACKEND_WEBSOCKET_URL=https://omisego.network/admin/socket
```

2. Install dependencies with `yarn install` if you don't have yarn please install it first https://yarnpkg.com/lang/en/docs/install/
3. Start the development server `yarn start` and go to `http://localhost:9000` and test it out.

_That's all, now you are ready to customize the admin panel as your own need._

### Production
To build the production app, use `yarn build` this will build a production version of admin panel and output in `/apps/admin_panel/priv/static` for the phoenix application to serve. **Note that the output path is the root of the eWallet app not the admin panel** 

### Testing
For unit test, just run `yarn test` and for linting run `yarn lint`

