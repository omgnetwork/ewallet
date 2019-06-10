# Admin Panel

The OmiseGO Wallet admin panel for a provider to manage staff, users, roles and permissions,
API access, tokens, transactions, etc.

## Usage

Running the Admin Panel in development mode locally allows you to modify the code and see changes in real-time. You may connect to any eWallet as a backend, which can be running locally or remotely which will depend on your config file.

### Development

1. You will first need to create the `.env` file located under the project's root directory `/apps/frontend/assets/` of the app with your own keys. There are 2 keys that is needed to be able to run and connect to the server `BACKEND_API_URL` and `BACKEND_WEBSOCKET_URL`

Example **.env** file
```
BACKEND_API_URL=https://omisego.network/admin/api
BACKEND_WEBSOCKET_URL=https://omisego.network/admin/socket
```

2. Install dependencies with `npm install`
3. Start the development server `npm run dev` and go to `http://localhost:9000` and test it out.

_That's all, now you are ready to customize the admin panel as your own need._

### Production
To build the production app, use `npm run build` this will build a production version of admin panel and output in `/apps/frontend/priv/static` for the phoenix application to serve. **Note that the output path is the root of the eWallet app not the admin panel** 

### Testing
For unit test, just run `npm run test` and for linting run `npm run lint`

