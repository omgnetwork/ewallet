OmiseGO eWallet
===============

The OmiseGO SDK provides various applications and tools that, once integrated, allow any person or company to set up an eWallet with a node of the OmiseGO blockchain. A person or company setting up the OmiseGO SDK in such a way is called a **provider**.

# Table of Contents

- [Introduction]()
- [Disclaimer]()
- [Overview]()
- [Getting Started]()
- [Coming Soon]()
- [Contributing]()
- [F.A.Q]()
- [Learning Resources]()

# TL;DR

- Web APIs
- SDKs

# Introduction

The OmiseGO SDK is composed of different components that can be grouped in the three following categories:

- __Server Applications__: A set of Elixir applications allowing a provider to store users and their balances, as well as initiating transactions between them and the provider’s balances. Those applications need to be deployed on a server and integrated by the provider through the provided HTTP API.
- __Server and client SDKs__: To facilitate the communication with the server applications, OmiseGO provides language-specific SDKs to integrate both on the server side (for sensitive requests) and on the client side (for non-sensitive requests).
- __Blockchain__: Once the server applications are plugged on the blockchain, the setup will become a node of the decentralized OmiseGO network and allow inter-wallet transactions to happen.

While all of these are being developed simultaneously, they have not all reach the same stage of advancement, which is why the OmiseGO SDK is not connected to the blockchain yet. For now, it acts as a silo-ed eWallet handling loyalty points. Once the blockchain is plugged, those loyalty points will become actual tradable cryptocurrencies.

__The sections below describe the server applications and server/client SDKs provided as part of the OmiseGO SDK.__

# OmiseGO SDK Integration Diagram

Here’s an overview of all the components and what needs to be integrated  by a provider (and how):

![A provider's setup](docs/images/provider_setup.jpg)

# Quick Start

## SDKs

## Sample Setup

OmiseGO has built a sample setup to show how the OmiseGO SDK can be integrated. It is a simple t-shirt store allowing users to receive loyalty points when buying something. They can then use those loyalty points to get a discount.

![OMGShop](docs/images/omgshop.png)

The code and documentation are available in the following repositories:

- [Server integration (Ruby)](https://github.com/omisego/sample-server)
- [Mobile Server integration (iOS)](https://github.com/omisego/sample-ios)
- [Mobile Server integration (Android)](https://github.com/omisego/sample-android)

## Setting up the OmiseGO SDK in local

## Dependencies

- [PostgreSQL](https://www.postgresql.org/): PostgreSQL is used to store most of the data for the eWallet API and local ledger.

- [ImageMagick](https://www.imagemagick.org/script/index.php): ImageMagick is used to format images in the admin panel.

- [Libsodium](https://github.com/jedisct1/libsodium): Sodium is a new, easy-to-use software library for encryption, decryption, signatures, password hashing and more. It is used to hash and encrypt/decrypt sensitive data.

---

To set up the OmiseGO SDK in local, follow the steps below:

TALK ABOUT ENVIRONMENT VARIABLES MINIMUM!

---

1. Install the [dependencies](#dependencies)

2. Install [Elixir](http://elixir-lang.github.io/install.html)

3. Once you have installed the [dependencies](#dependencies) and they are running, it's time to pull the code for the eWallet.

Let's start by cloning the eWallet, getting the dependencies and migrating the database:

```
git clone git@github.com:omisego/ewallet.git && cd ./ewallet
```

```
mix deps.get
```

Before we start the application, let's try running the tests:

```
MIX_ENV=test mix do ecto.create, ecto.migrate
```

```
mix test
```

If everything looks fine, we can create the development database:

```
mix do ecto.create, ecto.migrate
```

Everything is in place and we can now run the seeds to populate the eWallet database with initial data:

```
mix seed
```

_Note: The command above seeds the minimum amount of data to get the environment up and running. To play in development environment with some sample data, run `mix seed --sample` instead._

We can now start the application:

```
mix omg.server
```

Navigate to  `http://localhost:4000/api` in your browser and you should see the following JSON representation popping up:

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

- [eWallet API](/apps/ewallet_api/swagger-doc.yaml)
- [Admin API](/apps/admin_api/swagger-doc.yaml)

## Communicating with the server applications

The OmiseGO offers HTTP-RPC web APIs for communication. To make things easier to integrate, we've also created server-side and client-side SDKs wrapping those HTTP requests.

### HTTP

If you wish to use the HTTP-RPC web APIs directly, here are the Swagger specifications containing all the available endpoints and how to interact with them.

- [eWallet API](/apps/ewallet_api/swagger-doc.yaml)
- [Admin API](/apps/admin_api/swagger-doc.yaml)

### Server SDKs

To implement the sensitive calls on your side (such as crediting or debiting tokens from/to a user), we currently have the following server-side SDKs available:

- [Ruby SDK](https://github.com/omisego/ruby-sdk)

### Client SDKs

For the client side (non-sensitive calls), we currently have the following mobile SDKs available:

- [iOS SDK](https://github.com/omisego/ios-sdk)
- [Android SDK](https://github.com/omisego/android-sdk)

# Coming Soon


# Contributing

Coming soon.

# F.A.Q

Question?

# Learning Resources

- [A closer look at balances](/docs/balances.md)
