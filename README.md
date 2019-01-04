<img src="assets/logo.png" align="right" />

# OmiseGO eWallet

[![Build Status](https://jenkins.omisego.io/buildStatus/icon?job=omisego/ewallet/master)](https://jenkins.omisego.io/blue/organizations/jenkins/omisego%2Fewallet/activity?branch=master) [![Gitter chat](https://badges.gitter.im/omisego/ewallet.png)](https://gitter.im/omisego/ewallet)

This is the server application of the OmiseGO eWallet Suite that allows businesses and individuals (referred hereafter as the "provider") to setup and run their own digital wallet services through their own local ledger.

This server application and the SDKs will later be plugged onto a blockchain and connected to a decentralized exchange. **Blockchain capabilities are expected to be added as they become ready.** All active instances of the OmiseGO eWallet will then become a federated network forming the top layer of the OMG network, allowing the exchange of any currency into any other in a transparent way.

The SDKs for integrating your apps with the eWallet are available in [Ruby](https://github.com/omisego/ruby-sdk) ([sample server](https://github.com/omisego/sample-server)), [iOS](https://github.com/omisego/ios-sdk) ([sample app](https://github.com/omisego/sample-ios)) and [Android](https://github.com/omisego/android-sdk) ([sample app](https://github.com/omisego/sample-android)).

Point of Sale's merchant ([iOS](https://github.com/omisego/pos-merchant-ios) and [Android](https://github.com/omisego/pos-merchant-android)) and customer ([iOS](https://github.com/omisego/pos-client-ios) and [Android](https://github.com/omisego/pos-client-android)) apps are also available. They demonstrate how the eWallet server application and SDKs can be used to build apps for physical storefronts.

## Overview

Here is an overview of all the eWallet components and what needs to be integrated by a provider.

![A provider's Sample Setup](assets/provider_setup.jpg)

## Getting started

Pick one of the following setup approaches that best suits your needs:

Setup | Description | Recommended for
-----------|-------------|----------------
[Bare&#x2011;metal](docs/setup/bare_metal.md) | Set up directly onto your base operating system. You will need to install Elixir, project's dependencies and Postgres manually if you havn't. | Developers and DevOps preferring to manage all dependencies and configurations themselves for any purposes.
[Docker](docs/setup/docker.md) | A pre-packaged image for production uses. No build-time dependencies. Packaged with Distillery. | Developers and DevOps looking to integrate or deploy the eWallet without changing its internals.

Having trouble setting up the eWallet? Check the [Setup Troubleshooting Guide](docs/setup/troubleshooting.md).

## Documentation

Below are the links to the HTTP-RPC API documentations for the `master` branch. Note that the eWallet is not a centralized service and **the servers below are not for production uses.**

- Admin API ([**interactive**](https://ewallet.staging.omisego.io/api/admin/docs.ui) / [**yaml**](https://ewallet.staging.omisego.io/api/admin/docs.yaml) / [**json**](https://ewallet.staging.omisego.io/api/admin/docs.json)): Integrate with your server apps to perform higher-privilege operations, such as managing tokens, accounts, users, transactions, global settings, etc.
- Client API ([**interactive**](https://ewallet.staging.omisego.io/api/client/docs.ui) / [**yaml**](https://ewallet.staging.omisego.io/api/client/docs.yaml) / [**json**](https://ewallet.staging.omisego.io/api/client/docs.json)): Integrate with your client apps to transact on behalf of a specific user, such as creating a transaction request for a specific user, updating a user's settings, etc.

We also provide the [**Ruby SDK**](https://github.com/omisego/ruby-sdk) ([sample server](https://github.com/omisego/sample-server)), [**iOS SDK**](https://github.com/omisego/ios-sdk) ([sample app](https://github.com/omisego/sample-ios)) and [**Android SDK**](https://github.com/omisego/android-sdk) ([sample app](https://github.com/omisego/sample-android)) so you do not have to deal with the HTTP-RPC layer yourself.

Optionally, deeper dives into the eWallet are available:

- [Demo](docs/demo.md): Explore the sample shop server demos without setting up your own.
- [Guides](docs/guides/guides.md): Understand how the eWallet server works behind the scene.
- [Design](docs/design/design.md): Find out about the technical design decisions that revolve around the eWallet server.
- [Tests](docs/tests/tests.md): See how tests are organized for the eWallet server.
- [FAQ](docs/faq.md): Frequently asked questions.

You can also follow our advanced setup guides to customize your eWallet server:

- [Environment variables](docs/setup/advanced/env.md)
- [Settings](docs/setup/advanced/settings.md)
- [Clustering](docs/setup/advanced/clustering.md)
- [Upgrading](docs/setup/upgrading/)

## Contributing

Bug reports, feature suggestions, pull requests and feedbacks of any sorts are very welcomed.

Learn more from our [contributing guide](.github/CONTRIBUTING.md).

## Support

- [Issues](https://github.com/omisego/ewallet/issues): Browse or file a report for any bugs found
- [Gitter](https://gitter.im/omisego/ewallet): Discuss features and suggestions in real-time
- [StackOverflow](https://stackoverflow.com/questions/tagged/omisego): Search or create a new question with the tag `omisego`
- Need enterprise support or hosting solutions? [Get in touch with us](mailto:thibault@omisego.co) for more details

## Community efforts

We are thankful to our community for creating and maintaining these wonderful work that we otherwise could not have done ourselves. If you have ported any part of the OmiseGO eWallet to another platform, we will be very happy to list them here. [Submit us a pull request](https://github.com/omisego/ewallet/pulls).

- [Alainy/OmiseGo-Go-SDK](https://github.com/Alainy/OmiseGo-Go-SDK) (Golang)

Please note that these community tools and libraries are **not maintained by the OmiseGO team.**

## License

The OmiseGO eWallet is released under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
