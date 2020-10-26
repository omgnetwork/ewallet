# Admin Panel

The OMG Network Wallet admin panel for a provider to manage staff, users, roles and permissions,
API access, tokens, transactions, etc.

## Usage

Running the Admin Panel in development mode locally allows you to modify the code and see changes in real-time. You may connect to any eWallet as a backend, which can be running locally or remotely which will depend on your config file.

If the eWallet backend is running locally, you will need to configure to accept cross-origin requests by booting it with an additional environment variable:

```bash
CORS_ORIGIN=http://localhost:9000 mix omg.server
```

### Development

1. You will first need to create the `.env` file located in the project's root directory `/apps/frontend/assets/` of the app with your own keys. There are 2 keys that is needed to be able to run and connect to the server `REACT_APP_BACKEND_API_URL` and `REACT_APP_BACKEND_WEBSOCKET_URL`

Example **.env** file

```env
REACT_APP_BACKEND_API_URL='http://localhost:4000/api/admin'
REACT_APP_CLIENT_API_URL='http://localhost:4000/api/client'
REACT_APP_BACKEND_WEBSOCKET_URL='http://localhost:4000/api/admin/socket'
```

2. Install dependencies with `npm install`
3. Start the development server `npm run dev` and go to `http://localhost:9000` and test it out.

_That's all, now you are ready to customize the admin panel as you need._

### Production

To build the production app, use `npm run build`. This will output the static files into `/apps/frontend/priv/static` for the Phoenix application to serve. **Note that the output path is the root of the eWallet app not the admin panel**

### Testing

For unit test, just run `npm run test` and for linting run `npm run lint`
