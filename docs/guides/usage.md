# Usage

## Web APIs Interactive Documentation

- Admin API: [http://localhost:4000/api/admin/docs](http://localhost:4000/api/admin/docs)
  - Admin API yaml: [http://localhost:4000/api/admin/docs.yaml](http://localhost:4000/api/admin/docs.yaml)
  - Admin API json: [http://localhost:4000/api/admin/docs.json](http://localhost:4000/api/admin/docs.json)
- eWallet API: [http://localhost:4000/api/client/docs](http://localhost:4000/api/client/docs)
  - eWallet API yaml: [http://localhost:4000/api/client/docs.yaml](http://localhost:4000/api/client/docs.yaml)
  - eWallet API json: [http://localhost:4000/api/client/docs.json](http://localhost:4000/api/client/docs.json)

## Making your first requests

Here are some steps to get you started with the fun, they can all be performed by accessing the Swagger UI linked above:

1.  In the Admin API, configure the authentication at the top using the keys generated in the seeding step.
2.  Log yourself in and get the returned authentication token. In case you're getting an invalid auth scheme, double check that you're using `OMGAdmin` with the base64 encoded version of `API_KEY_ID:API_KEY` (with no `\n`, some programming languages add them).
3.  Configure the user authentication using the authentication token you've received in the previous step.
4.  Create a token using `/token.create`. You can specify the optional `amount` parameter to do an initial minting.
5.  After that you're ready to start messing around with the eWallet API. You can create yourself a user using one of the server calls and credit/debit tokens!

## Communicating with the eWallet

If Swagger UI is not enough, you can start communicating with the web APIs using any programming language of your choice, either by using the HTTP-RPC endpoints directly or by using one of the available SDKs.

### HTTP-RPC WEB APIs

If you wish to use the HTTP-RPC web APIs directly, here are the OpenAPI specifications containing all the available endpoints and how to interact with them. You can access those interactive documentations on any running eWallet application, including the ones you deploy yourself! The eWallet API docs live under `/api/client/docs` and the Admin API ones under `/api/admin/docs`.

-   [eWallet API](https://ewallet.demo.omisego.io/api/client/docs)
-   [Admin API](https://ewallet.demo.omisego.io/api/admin/docs)

When using the eWallet API, be sure to have `/api/client` at the end of your base URL (e.g. `https://yourdomain.com/api/client`). For the Admin API, it should include `/api/admin` (e.g. `https://yourdomain.com/api/admin`).

### Server SDKs

To implement the sensitive calls in your server-side applications (such as crediting or debiting tokens from/to a user), the following SDKs are available:

-   [Ruby SDK](https://github.com/omisego/ruby-sdk)

### Client SDKs

For client-side applications (non-sensitive calls), the following SDKs are available:

-   [iOS SDK](https://github.com/omisego/ios-sdk)
-   [Android SDK](https://github.com/omisego/android-sdk)

### Not seeing what you need?

If none of the current SDKs matches your needs, you can create it! Get in touch with us [on Gitter](https://gitter.im/omisego/ewallet) and let us know. We'll be happy to help you implement it and, if your SDK meets our standards, support it as one of our official SDK.
