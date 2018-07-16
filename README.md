<img src="assets/logo.png" align="right" />

# OmiseGO eWallet Server

[![Build Status](https://jenkins.omisego.io/buildStatus/icon?job=omisego/ewallet/master)](https://jenkins.omisego.io/blue/organizations/jenkins/omisego%2Fewallet/activity?branch=master) [![Gitter chat](https://badges.gitter.im/omisego/ewallet.png)](https://gitter.im/omisego/ewallet)

This is the main server component of the OmiseGO eWallet SDKs that allows businesses and individuals to setup and run their own digital wallet services through their own local ledger.

This server component and its sibling SDKs will later be plugged onto a blockchain and connected to a decentralized exchange. **Blockchain capabilities are expected to be added as they become ready.** All active instances of the OmiseGO eWallet will then become a federated network forming the top layer of the OMG network, allowing the exchange of any currency into any other in a transparent way.

The OmiseGO eWallet SDKs are also available in [Ruby](https://github.com/omisego/ruby-sdk) ([sample server](https://github.com/omisego/sample-server)), [iOS](https://github.com/omisego/ios-sdk) ([sample app](https://github.com/omisego/sample-ios)), [Android](https://github.com/omisego/android-sdk) ([sample app](https://github.com/omisego/sample-android)).

## Getting started

Pick one of the 3 following approaches that best suits your needs:

- **[Docker setup](docs/setup/docker.md) (recommended)**: The fastest way to get the server up and running with minimum configurations.
- [Vagrant setup](docs/setup/vagrant.md): Sets up a flexible development environment. Recommended for contributing to the code base.
- [Bare-metal setup](docs/setup/bare_metal.md): Sets up directly onto your base operating system. No virtualization involved.

## Documentation

Choose the area that you are interested to learn more about the eWallet server:

- [Demo](docs/demo.md): Explore available APIs without setting up your own servers.
- [Guides](docs/guides/guides.md): Understand how the eWallet server works behind the scene.
- [Design](docs/design/design.md): Find out how the eWallet server was built and the technical design decisions that revolve around it.
- [Tests](docs/tests/tests.md): See how tests are organized for the eWallet server.

Optionally, you can also follow our advanced setup guides to customize your eWallet server:

- [Environment variables](docs/setup/advanced/env.md)
- [Clustering](docs/setup/advanced/clustering.md)
- [Adhoc settings](docs/setup/adhoc/)

## Contributing

Bug reports, feature suggestions, pull requests and feedbacks of any sorts are very welcomed.

Learn more from our [contributing guide](.github/CONTRIBUTING.md).

## Support

- [Issues](https://github.com/omisego/ewallet/issues): Browse or file a report for any bugs found
- [Gitter](https://gitter.im/omisego/ewallet): Discuss features and suggestions in real-time
- [StackOverflow](https://stackoverflow.com/questions/tagged/omisego): Search or create a new question with the tag `omisego`
- Need enterprise support or hosting solutions? [Get in touch with us](mailto:thibault@omisego.co) for more details

## Community efforts

We are thankful of our community for creating and maintaining these wonderful work that we otherwise could not have done ourselves. If you have ported any part of the OmiseGO eWallet SDKs to another platform, we will be very happy to list them here. [Submit us a pull request](pulls).

- [Alainy/OmiseGo-Go-SDK](https://github.com/Alainy/OmiseGo-Go-SDK) (Golang)

Please note that these community tools and libraries are **not maintained by the OmiseGO team.**

## License

The OmiseGO eWallet is released under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
