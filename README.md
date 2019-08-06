<img src="assets/logo.png" align="right" />

# OmiseGO eWallet Server

[![](https://img.shields.io/circleci/project/github/omisego/ewallet/master.svg)](https://circleci.com/gh/omisego/ewallet/tree/master)
[![](https://img.shields.io/gitter/room/omisego/ewallet.svg)](https://gitter.im/omisego/ewallet)
[![](https://img.shields.io/github/issues/omisego/ewallet.svg)](https://img.shields.io/github/issues/omisego/ewallet.svg)

**OmiseGO eWallet Server** is a server application in OmiseGO eWallet Suite that allows a provider (businesses or individuals) to setup and run their own digital wallet services through a local ledger, and to a decentralized blockchain exchange in the future to form a federated network on the OMG network allowing exchange of any currency into any other in a transparent way.

## Getting started

* [Install quickly on macOS or Linux, or bare metal install on other platforms](https://docs.omisego.co/docs/install-ewallet-server)
* [Creating the database and populate it with initial data, and update the configuration key](https://docs.omisego.co/docs/install-ewallet-server#section-create-and-update-the-database)
* [Upgrade eWallet Server](https://docs.omisego.co/docs/upgrade-ewallet-server)


## Documentation

Documentation can found at the OmiseGO developer docs website, and in the [docs](docs/) directory. It is recommended to take a look at the documentation of the OmiseGO eWallet Server you are running.

### API documentation

OmiseGO eWallet Server is meant to be run by the provider, and thus API documentation is available in the OmiseGO eWallet Server itself rather than as online documentation. You may review the API documentation at the following locations in the OmiseGO eWallet Server setup.

-   `/api/admin/docs.ui` for Admin API, used by server apps to manage tokens, accounts, transactions, global settings, etc.
-   `/api/client/docs.ui` for Client API, used by client apps to create transaction on behalf of user, user's settings, etc.

In case you want to explore the API documentation without installing the OmiseGO eWallet Server, you may use our [OmiseGO eWallet Staging](https://ewallet.staging.omisego.io/). Please note that OmiseGO eWallet Staging tracks development release and there might be API differences from the stable release.

-   [Admin API documentation](https://ewallet.staging.omisego.io/api/admin/docs.ui) ([Swagger JSON](https://ewallet.staging.omisego.io/api/admin/docs.json), [Swagger YAML](https://ewallet.staging.omisego.io/api/admin/docs.yaml))
-   [Client API documentation](https://ewallet.staging.omisego.io/api/client/docs.ui) ([Swagger JSON](https://ewallet.staging.omisego.io/api/client/docs.json), [Swagger YAML](https://ewallet.staging.omisego.io/api/client/docs.yaml))

## SDKs

These are SDKs for integrating with the OmiseGO eWallet Server. For example, to integrate a loyalty point system built on OmiseGO eWallet Server into an existing system.

-   [Ruby SDK](https://github.com/omisego/ruby-sdk) ([Sample Server](https://github.com/omisego/sample-server))
-   [iOS SDK](https://github.com/omisego/ios-sdk) ([Sample App](https://github.com/omisego/sample-ios))
-   [Android SDK](https://github.com/omisego/android-sdk) ([Sample App](https://github.com/omisego/sample-android))

It is also possible to run OmiseGO eWallet Server in a standalone mode without needing to integrate into an existing system. These apps demonstrate the capabilities of the OmiseGO eWallet Server as a physical Point-of-Sale server and client.

-   [iOS PoS for Merchant](https://github.com/omisego/pos-merchant-ios)
-   [iOS PoS for Customer](https://github.com/omisego/pos-client-ios)
-   [Android PoS for Merchant](https://github.com/omisego/pos-merchant-android)
-   [Android PoS for Customer](https://github.com/omisego/pos-client-android)

### Community Efforts

We are thankful to our community for creating and maintaining these wonderful works that we otherwise could not have done ourselves. If you have ported any part of the OmiseGO eWallet Server to another platform, we will be happy to list them here. [Submit us a pull request](https://github.com/omisego/ewallet/pulls).

-   [Alainy/OmiseGo-Go-SDK](https://github.com/Alainy/OmiseGo-Go-SDK) (Golang)
-   [block-base/ewallet-js](https://github.com/block-base/ewallet-js) (JavaScript)

## Contributing

Contributing to the OmiseGO eWallet Server can be contributions to the code base, bug reports, feature suggestions or any sort of feedback. Please learn more from our [contributing guide](.github/CONTRIBUTING.md).

## Support

The OmiseGO eWallet Server team closely monitors the following channels.

-   [GitHub Issues](https://github.com/omisego/ewallet/issues): Browse or file a report for any bugs found
-   [Gitter](https://gitter.im/omisego/ewallet): Discuss features and suggestions in real-time
-   [Stack Overflow](https://stackoverflow.com/questions/tagged/omisego): Search or create a new question with the tag `omisego`

If you need enterprise support or hosting solutions, please [get in touch with us](mailto:thibault@omisego.co) for more details.

## License

The OmiseGO eWallet Server is licensed under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0)
