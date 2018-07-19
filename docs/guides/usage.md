# Usage

You can start communicating with the web APIs using any programming language of your choice,
either by using the HTTP-RPC endpoints directly or by using one of the available SDKs.

## HTTP-RPC WEB APIs

If you wish to use the HTTP-RPC web APIs directly, here are the OpenAPI specifications containing all the available endpoints and how to interact with them.

You can access those interactive documentations on any running eWallet application, including the ones you deploy yourself!

**Admin API**
- Interactive docs: [http://localhost:4000/api/admin/docs](http://localhost:4000/api/admin/docs)
- OpenAPI YAML specs: [http://localhost:4000/api/admin/docs.yaml](http://localhost:4000/api/admin/docs.yaml)
- OpenAPI JSON specs: [http://localhost:4000/api/admin/docs.json](http://localhost:4000/api/admin/docs.json)

**eWallet API**
- Interactive docs: [http://localhost:4000/api/client/docs](http://localhost:4000/api/client/docs)
- OpenAPI YAML specs: [http://localhost:4000/api/client/docs.yaml](http://localhost:4000/api/client/docs.yaml)
- OpenAPI JSON specs: [http://localhost:4000/api/client/docs.json](http://localhost:4000/api/client/docs.json)

## Server SDKs

To implement the sensitive calls in your server-side applications (such as crediting or debiting tokens from/to a user), the following SDKs are available:

- [Ruby SDK](https://github.com/omisego/ruby-sdk)

## Client SDKs

For client-side applications (non-sensitive calls), the following SDKs are available:

- [iOS SDK](https://github.com/omisego/ios-sdk)
- [Android SDK](https://github.com/omisego/android-sdk)

## Not seeing what you need?

If none of the current SDKs matches your needs, you can create it! Get in touch with us [on Gitter](https://gitter.im/omisego/ewallet) and let us know. We'll be happy to help you implement it and, if your SDK meets our standards, support it as one of our official SDK.
