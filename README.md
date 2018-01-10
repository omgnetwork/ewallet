# OmiseGO eWallet

## Getting Started

1. OmiseGO SDK Overview
2. OmiseGO SDK Integration Diagram
3. Server-side components
4. Client-side components
5. Integrating the OmiseGO SDK

### OmiseGO SDK Overview

The OmiseGO SDK provides various applications and tools that, once integrated, allows any person or company to set up an eWallet with a node of the OmiseGO blockchain. A person or company setting up the OmiseGO SDK in such a way is called a **provider**.

The OmiseGO SDK is composed of different components that can be grouped in the three following categories:

1. Server Applications: A set of Elixir applications allowing a provider to store users and their balances, as well as initiating transactions between them and the provider’s balances. Those applications need to be deployed on a server and integrated by the provider through the provided HTTP API.
2. Server and client SDKs: To facilitate the communication with the server applications, OmiseGO provides language-specific SDKs to integrate both on the server side (for sensitive requests) and on the client side (for non-sensitive requests).
3. Blockchain: Once the server applications are plugged on the blockchain, the setup will become a node of the decentralized OmiseGO network and allow inter-wallet transactions to happen.

While all of these are being developed simultaneously, they have not all reach the same stage of advancement, which is why the OmiseGO SDK is not actually plugged to the blockchain yet. For now, it acts as a silo-ed eWallet handling loyalty points. Once the blockchain is plugged, those loyalty points will become actual tradable cryptocurrencies.

__The sections below describe the server applications and server/client SDKs provided as part of the OmiseGO SDK.__

### OmiseGO SDK Integration Diagram
Here’s an overview of all the components and what needs to be integrated  by a provider (and how):

![A provider's setup](docs/images/provider_setup.png)

### Understanding the server-side applications
- entities
- swagger
- link to each project

#### Entities
- Minted Tokens
- Mints
- Accounts
- Users
- Balances
- Client API Keys
- Server API Keys
- Auth tokens
- Transactions

#### Components
- eWallet API
- Local Ledger
- Admin Panel API
- Admin Panel
- Request Logger
- Blockchain Gateway

#### Dependencies
- PostgreSQL
- RabbitMQ
- Libsodium

#### Deployment
- Deploying with Docker Kubernetes
- Deploying manually
- Server configuration options

### Communicating with the server
#### HTTP
- eWallet API
- Admin Panel API

#### Server SDKs
- Ruby SDK

#### Mobile SDKs
- iOS SDK
- Android SDK

##### iOS
##### Android

### Integrating the SDKs

#### Sample Setup

#### Settting up the OmiseGO SDK

### Diving further

- Balances
