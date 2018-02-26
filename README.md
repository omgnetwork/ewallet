OmiseGO eWallet
===============

The OmiseGO eWallet is an Elixir application freely available for anyone who wishes to run a (local) ledger through a web interface.

**The eWallet will later be plugged to a blockchain and connected to a decentralized exchange. All the eWallets will then become a federated network forming the top layer of the OMG network, allowing the exchange of any currency into any other in a transparent way.**

__In the rest of this document, a person or company setting up this eWallet is called a provider.__

---

# Disclaimer

## Beta

The OmiseGO eWallet and SDKs are still under heavy development, and therefore, in "beta". This means things might break or change suddenly. We are moving fast, and until the official release, we'd like to keep it that way.

__Use at your own risk.__

(Still, we will do our best to keep breaking changes to the minimum and notify when such events happen)

## Blockchain

Do not expect to find anything related to blockchain integration __yet__. It will come, when it's ready.

# Table of Contents

- [Introduction](#introduction)
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Deploying the OmiseGO eWallet](#deploying-the-omisego-ewallet)
- [Coming Soon](#coming-soon)
- [Contributing](#contributing)
- [F.A.Q](#faq)
- [Going Further](#going-further)

---

# TL;DR

- eWallet Web API Docs: [stable](https://ewallet.demo.omisego.io/api/swagger) /  [current](https://ewallet.staging.omisego.io/api/swagger)

- Admin Web API Docs: [stable](https://ewallet.demo.omisego.io/admin/api/swagger) / [current](https://ewallet.staging.omisego.io/admin/api/swagger)

- SDKs:
  - [Ruby](https://github.com/omisego/ruby-sdk)
  - [iOS](https://github.com/omisego/ios-sdk)
  - [Android](https://github.com/omisego/android-sdk)

- Sample Apps:
  - [Server integration (Ruby)](https://github.com/omisego/sample-server)
  - [Mobile integration (iOS)](https://github.com/omisego/sample-ios)
  - [Mobile integration (Android)](https://github.com/omisego/sample-android)

---

# Introduction

What is commonly called as the OmiseGO SDK is actually composed of a few different applications.

- __eWallet__: Currently only acting as local ledger (as opposed to a decentralized one), it will later on be plugged on a blockchain with minimal changes required for providers. The eWallet needs to be deployed on a server.
- __Server and client SDKs__: To simplify the communication with the eWallet, OmiseGO provides language-specific SDKs.

Currently, the easiest use-case to understand what the eWallet can do is to see it as a loyalty point ledger. Once the blockchain is plugged, those points will become actual tradable cryptocurrencies.

---

# OmiseGO SDK Integration Diagram

Here’s an overview of all the components and what needs to be integrated by a provider (and how):

![A provider's Sample Setup](docs/images/provider_setup.jpg)

---

# Sample Setup

OmiseGO has built a sample setup to demonstrate how the OmiseGO eWallet and the SDKs can be used. It is a simple t-shirt store allowing users to receive loyalty points when buying something. They can then use those loyalty points to get a discount.

![OMGShop](docs/images/omgshop.png)

The code and documentation are available in the following repositories:

- [Server integration (Ruby)](https://github.com/omisego/sample-server)
- [Mobile Server integration (iOS)](https://github.com/omisego/sample-ios)
- [Mobile Server integration (Android)](https://github.com/omisego/sample-android)

The demo server applications have been deployed and are available at the following URLs:

- [OMGShop - Ruby on Rails](https://sample-shop.demo.omisego.io/)
- [OMGShop - eWallet](https://ewallet.demo.omisego.io/)

---

# Quick Start

The following section will get you up to speed on the eWallet and show you how to deploy it in local.

## Installing the dependencies

Be sure to have the following applications installed and running on your machine.

- [PostgreSQL](https://www.postgresql.org/): PostgreSQL is used to store most of the data for the eWallet API and local ledger.

- [ImageMagick](https://www.imagemagick.org/script/index.php): ImageMagick is used to format images in the admin panel. Tested with version `> 7.0.7-22`.

- [Libsodium](https://github.com/jedisct1/libsodium): Sodium is a new, easy-to-use software library for encryption, decryption, signatures, password hashing and more. It is used to hash and encrypt/decrypt sensitive data.

- [Elixir](http://elixir-lang.github.io/install.html): Elixir is a dynamic, functional language designed for building scalable and maintainable applications.

- [Git](https://git-scm.com/): Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

## Getting the code

Once you have installed the all the dependencies and they are running, it's time to pull the eWallet code. To do so, let's use `git`:

```
git clone git@github.com:omisego/ewallet.git && cd ./ewallet
```

Feel free to look around!

## Setting up

We now need to pull the Elixir dependencies:

```
mix deps.get
```

You may need to set some environment variables before proceeding.

__It is important to understand that the eWallet actually connects to two different databases. The first one, the local ledger database, is only used to store transactions, making it easier for audits. The second one contains, well, everything else.__

In development, you should only have to set the `DATABASE_URL` and `LOCAL_LEDGER_DATABASE_URL` if your local PostgreSQL installation requires authentication.

- `DATABASE_URL`: The URL where the main database can be accessed. Defaults to `postgres://localhost/ewallet_dev` in `dev`, `postgres://localhost/ewallet_test` in `test`.
- `LOCAL_LEDGER_DATABASE_URL`: The URL where the ledger database can be accessed. Defaults to `postgres://localhost/local_ledger_dev` in `dev`, `postgres://localhost/local_ledger_test` in `test`.

The `ewallet_dev` and `local_ledger_dev` don't need to be created beforehand as long as the database URLs contain credentials allowing this kind of operations.

In some cases, you might also want to customize the following ones, depending on your development setup:

- `BASE_URL`: The URL where the application can be accessed. Defaults to `http://localhost:4000`.
- `PORT`: The port where the application can be accessed: Default to `4000`.

To learn more about all the environment variables available for production deployments (or if you want to get fancy in local), checkout [this doc](/docs/setup/env.md).

## Running the tests

Before we start the application, let's try running the tests. Create the test databases:

```
MIX_ENV=test mix do ecto.create, ecto.migrate
```

```
mix test
```

```
OUTPUT
```

All the tests should pass. If some tests are failing, double-check you have install all the dependencies. If you keep getting the failures, you can get in touch with us on [Rocket](https://chat.omisego.network/channel/ewallet-sdk)!

## Migrating the development database

If all the tests passed, we can create the development databases:

```
mix do ecto.create, ecto.migrate
```

## Inserting some data

Everything is in place and we can now run the seeds to populate the eWallet database with some initial data:

```
mix seed
```

__Note: The command above seeds the minimum amount of data to get the environment up and running. To play in development environment with some sample data, run `mix seed --sample` instead.__

## Booting up

Time to start the application!

```
mix omg.server
```

Navigate to `http://localhost:4000/api` in your browser and you should see the following `JSON` representation popping up:

```
{
  "success": true,
  "services": {
    "local_ledger": true,
    "ewallet": true
  }
}
```

All set! Start playing around with the API using the Swagger docs below to learn more about the available endpoints. Enjoy!

## Web APIs Interactive Documentation

- Admin API: [http://localhost:4000/admin/api/swagger](http://localhost:4000/admin/api/swagger)
- eWallet API: [http://localhost:4000/api/swagger](http://localhost:4000/api/swagger)

## Making your first requests

Here are some steps to get you started with the fun, they can all be performed by accessing the Swagger linked above:

1. In the Admin API, configure the authentication at the top using the keys generated in the seeding step.
2. Log yourself in and get the returned authentication token. In case you're getting an invalid auth scheme, double check that you're using `OMGAdmin` with the base64 encoded version of `API_KEY_ID:API_KEY` (with no `\n`, some programming languages add them).
3. Configure the user authentication using the authentication token you've received in the previous step.
4. Create a minted token using `/minted_token.create`. You can specify the optional `amount` parameter to do an initial minting.
5. After that you're ready to start messing around with the eWallet API. You can create yourself a user using one of the server calls and credit/debit tokens!

## Communicating with the eWallet

If Swagger is not enough, you can start communicating with the web APIs using any programming language of your choice, either by using the HTTP-RPC endpoints directly or by using one of the available SDKs.

### HTTP-RPC WEB APIs

If you wish to use the HTTP-RPC web APIs directly, here are the Swagger specifications containing all the available endpoints and how to interact with them. You can access those interactive documentations on any running eWallet application, including the ones you deploy yourself! The eWallet API docs live under `/api/swagger` and the Admin API ones under `/admin/api/swagger`.

- [eWallet API](https://ewallet.demo.omisego.io/api/swagger)
- [Admin API](https://ewallet.demo.omisego.io/admin/api/swagger)

### Server SDKs

To implement the sensitive calls in your server-side applications (such as crediting or debiting tokens from/to a user), the following SDKs are available:

- [Ruby SDK](https://github.com/omisego/ruby-sdk)

### Client SDKs

For client-side applications (non-sensitive calls), the following SDKs are available:

- [iOS SDK](https://github.com/omisego/ios-sdk)
- [Android SDK](https://github.com/omisego/android-sdk)

### Not seeing what you need?

If none of the current SDKs matches your needs, you can create it! Get in touch with us [on Rocket](https://chat.omisego.network/channel/ewallet-sdk) and let us know. We'll be happy to help you implement it and, if your SDK meets our standards, support it as one of our official SDK.

---

# Deploying the OmiseGO eWallet

OmiseGO offers hosting solutions for the OmiseGO SDK. [Get in touch](mailto:thibault@omise.co) if you're interested.

Deploying the OmiseGO SDK can be done on any infrastructure. For security reasons, it is recommended to run the applications on one server and the databases on a different one.

More information about deployment will be available soon.

---

# Coming Soon

In this section, we will be sharing some of the next features the OmiseGO team will be working on.

- Integrate the Admin Panel in the eWallet.
- Re-design and finalize the first version of the Admin Panel.
- Implement the Request Logger sub-app for easy logging and debugging.
- Refactor and split the factories files. Make smarter use of them throughout the tests.
- Refactor and unify the test helpers for minting.

---

# F.A.Q

- Can I use the eWallet right now?
- When will the eWallet be official released (out of Beta)?
- When will the eWallet be plugged on the blockchain?
- Can I help?
- Why going with HTTP-RPC vs RESTful?
- Is the eWallet a centralized service?

---

# Going Further

Here are some resources if you want to learn more about how the eWallet works.

- [All ENV needed to run the eWallet](/docs/setup/env.md)
- [Integration Responsibilities](/docs/setup/integration.md)
- [eWallet Entites](/docs/design/entities.md)
- [eWallet Components](/docs/design/components.md)
- [A closer look at balances](/docs/design/balances.md)

---

# Contributing

See [how you can help](.github/CONTRIBUTING.md).

---

# License

The OmiseGO eWallet is released under the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
