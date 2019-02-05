<img src="assets/logo.png" align="right" />

# OmiseGO eWallet Server

[![](https://img.shields.io/circleci/project/github/omisego/ewallet/master.svg)](https://circleci.com/gh/omisego/ewallet/tree/master)
[![](https://img.shields.io/gitter/room/omisego/ewallet.svg)](https://gitter.im/omisego/ewallet)
[![](https://badge.waffle.io/omisego/ewallet.svg?columns=Cycle%20To%20Do,In%20Progress,Review,Done)](https://waffle.io/omisego/ewallet)

**OmiseGO eWallet Server** is a server application in OmiseGO eWallet Suite that allows a provider (businesses or individuals) to setup and run their own digital wallet services through a local ledger, and to a decentralized blockchain exchange in the future to form a federated network on the OMG network allowing exchange of any currency into any other in a transparent way.

## Getting started

The quickest way to get OmiseGO eWallet Server running on macOS and Linux is to use [Docker-Compose](https://docs.docker.com/compose/install/).

1. Install [Docker](https://docs.docker.com/install/) and [Docker-Compose](https://docs.docker.com/compose/install/)

2. Download OmiseGO eWallet Server's [docker-compose.yml](https://raw.githubusercontent.com/omisego/ewallet/v1.1/docker-compose.yml):

    ```shell
    curl -O -sSL https://raw.githubusercontent.com/omisego/ewallet/v1.1/docker-compose.yml
    ```

3. Create `docker-compose.override.yml` either [manually](https://docs.docker.com/compose/extends/) or use auto-configuration script:

    ```
    curl -O -sSL https://raw.githubusercontent.com/omisego/ewallet/v1.1/docker-gen.sh
    chmod +x docker-gen.sh
    ./docker-gen.sh > docker-compose.override.yml
    ```

4. Initialize the database and start the server:

    ```
    docker-compose run --rm ewallet initdb
    docker-compose run --rm ewallet seed
    docker-compose up -d
    ```

Had a problem during the installation? See [Setup Troubleshooting Guide](docs/setup/troubleshooting.md).

For other platforms or a more advanced setup, see alternative installation below.

### Alternative installation

-   [Bare metal installation](docs/setup/bare_metal.md)

## Upgrade

- Upgrading from `v1.0`? See [Upgrading from v1.0.0 to v1.1.0](docs/setup/upgrading/v1.1.0.md).
- Upgrading from other versions? See [Upgrading the eWallet Server](docs/setup/upgrading).

## Commands

Docker image entrypoint is configured to recognize most commands that are used during normal operations. The way to invoke these commands depend on the installation method you choose.

-   In case of Docker-Compose, use `docker-compose run --rm ewallet <command>`
-   In case of Docker, use `docker run -it --rm omisego/ewallet <command>`
-   In case of bare metal, see also bare metal installation instruction.

### initdb

For example:

-   `docker-compose run --rm ewallet initdb` (Docker-Compose)
-   `docker run -it --rm omisego/ewallet:latest initdb` (Docker)

These commands create the database if not already created, or upgrade them if necessary. This command is expected to be run every time you have upgraded the version of OmiseGO eWallet Suite.

### seed

For example:

-   `docker-compose run --rm ewallet seed` (Docker-Compose)
-   `docker run -it --rm omisego/ewallet:latest seed` (Docker)

These commands create the initial data in the database. If `seed` is run without arguments, the command will seed initial data for production environment. The `seed` command may be configured to seed with other kind of seed data:

-   `seed --sample` will seed a sample data suitable for evaluating OmiseGO eWallet Server.
-   `seed --e2e` will seed a data for [end-to-end testing](docs/setup/advanced/env.md).

### config

For example:

-   `docker-compose run --rm ewallet config <key> <value>` (Docker-Compose)
-   `docker run -it --rm omisego/ewallet:latest config <key> <value>` (Docker)

These commands will update the configuration key (see also [settings documentation](docs/setup/advanced/settings.md)) in the database. For some keys which require whitespace, such as `gcs_credentials`, you can prevent string splitting by putting them in a single or double-quote, e.g. `config gcs_credentials "gcs configuration"`.

## Documentation

All documentations can found in the [docs](docs/) directory. You are recommended to take a look at the documentation of respective version of OmiseGO eWallet Server you are running.

### API documentation

OmiseGO eWallet Server is meant to be run by the provider, and thus API documentation is available in the OmiseGO eWallet Server itself rather than as an online documentation. You may be the API documentation at the following location in OmiseGO eWallet Server setup.

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

It is also possible to run OmiseGO eWallet Server in a standalone mode without needing to integrate into existing system. These apps demonstrate the capabilities of the OmiseGO eWallet Server as a physical Point-of-Sale server and client.

-   [iOS PoS for Merchant](https://github.com/omisego/pos-merchant-ios)
-   [iOS PoS for Customer](https://github.com/omisego/pos-client-ios)
-   [Android PoS for Merchant](https://github.com/omisego/pos-merchant-android)
-   [Android PoS for Customer](https://github.com/omisego/pos-client-android)

### Community Efforts

We are thankful to our community for creating and maintaining these wonderful work that we otherwise could not have done ourselves. If you have ported any part of the OmiseGO eWallet Server to another platform, we will be happy to list them here. [Submit us a pull request](https://github.com/omisego/ewallet/pulls).

-   [Alainy/OmiseGo-Go-SDK](https://github.com/Alainy/OmiseGo-Go-SDK) (Golang)
-   [block-base/ewallet-js](https://github.com/block-base/ewallet-js) (JavaScript)

## Contributing

Contributing to the OmiseGO eWallet Server can be contributions to the code base, bug reports, feature suggestions or any sorts of feedbacks. Please learn more from our [contributing guide](.github/CONTRIBUTING.md).

## Support

The OmiseGO eWallet Server team closely monitors the following channels.

-   [GitHub Issues](https://github.com/omisego/ewallet/issues): Browse or file a report for any bugs found
-   [Gitter](https://gitter.im/omisego/ewallet): Discuss features and suggestions in real-time
-   [Stack Overflow](https://stackoverflow.com/questions/tagged/omisego): Search or create a new question with the tag `omisego`

If you need enterprise support or hosting solutions, please [get in touch with us](mailto:thibault@omisego.co) for more details.

## License

The OmiseGO eWallet Server is licensed under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0)
