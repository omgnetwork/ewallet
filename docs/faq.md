# Frequently Asked Questions

## Can I use the eWallet right now?

Sure! You can deploy it on a server (or run it locally) and start using it as a ledger. Refer to the [getting started](/README.md#getting-started) section for more information.

## Can I help?

Of course! Check out our [contribution guidelines](/.github/CONTRIBUTING.md) to get started.

## Why going with HTTP-RPC vs RESTful?

We decided to stay as protocol-agnostic as possible and not follow HTTP conventions. Therefore, the web APIs only allows the `POST` method and returns `200` or `500` codes with custom representations and errors.

## Is the eWallet a centralized service?

Each provider is responsible for running its own version of the eWallet. To get started, we offer hosting solutions but the long term goal is to have a federated network of eWallets running on top of a decentralized blockchain with no centralization.

More questions? Get in touch with us on [Gitter](https://gitter.im/omisego/ewallet)!
