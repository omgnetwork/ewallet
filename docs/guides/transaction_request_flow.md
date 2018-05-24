# Transaction Request Flow

## Introduction

Transaction requests are a way to create pre-transactions with only one side (either sender or receiver). That pre-transaction will become a full transaction once the other side has consumed it.


Here is a quick example to give you a better idea of how it works:

1. Alice generates a transaction request to receive 10 OMG. The transaction request ID can be embedded in a QR code to provide a better user experience.
2. Alice shows her QR code to Bob.
3. Bob scans it, see the transaction request, updates some parts of it if needed, finalizes it and sends 10 OMG to Alice.

That's the simple version. Transaction requests come with a bunch of options to make them as flexible as possible.

## A look at transaction requests

When creating transaction requests, a certain number of fields are optional but allow the configuration of the request. Walking through those fields is a good way to get a better understanding.

See [the Swagger doc](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/transaction_request_create) for more details.

Here is the model attributes when creating transaction requests:

```yaml
type:
  type: string
  enum:
    - send
    - receive
token_id:
  type: string
  description: "The token ID to use for the transaction."
amount:
  type: integer
  default: null
  description:
    "The amount to transfer. If not specified, the consumption will need to set
     the amount."
correlation_id:
  type: string
  default: null
  description: "Optional unique identifier to tie a request with your system."
account_id:
  type: string
  description: The owner of the given address. Either account_id or provider_user_id needs to be filled.  
provider_user_id:
  type: string
  description: The owner of the given address. Either account_id or provider_user_id needs to be filled. 
address:
  type: string
  description:
    "If not specified, the current user's primary balance will be used.
     If specified, it needs to be one of the account's or user's addresses."
require_confirmation:
  type: boolean
  default: false
  description:
    "Indicates if a consumption of the created request needs to be approved before
    being processed."
max_consumptions:
  type: integer
  default: null
  description:
    "The number of times this created request can be consumed."
consumption_lifetime:
  type: integer
  default: null
  description:
    "The lifetime in milliseconds of how long a consumption can stay
     'pending' before being expired. If a consumption is not approved before its
     expiration date, it will become invalid and be cancelled. This property
     can be used to avoid stale consumptions blocking the 'max_consumptions' count."
expiration_date:
  type: string
  default: null
  description:
    "The datetime at which the created request should expire (no one will be
     able to consume it anymore). The format is yyyy-MM-dd'T'HH:mm:ssZZZZZ."
allow_amount_override:
  type: boolean
  default: true
  description:
    "Defines if the amount set in the created request can be overriden in a
     consumption. Cannot be set to true if the amount property is not set at
     creation"
metadata:
  type: object
  default: {}
encrypted_metadata:
  type: object
  default: {}
```

## Flow

Here is the flow used in the sample OMGShop application:

1. Alice using [the OMGShop iOS application](https://github.com/omisego/sample-ios) generates a transaction request. The endpoint called is [/me.create_transaction_request](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/create_transaction_request). The `id` of that is embedded in a QR Code and displayed on the screen of the device.

2. Bob uses the scan feature in OMGShop on his own device to scan the QR Code. The app uses [/me.get_transaction_request](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/get_transaction_request) to get the details of the request.

3. Bob can then see what kind of request he just scanned. Is it going to send or receive money, the amount, and so on. He can then decide to consume the request using [/me.consume_transaction_request](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/consume_transaction_request).

4. The path can now have two different outputs. If the request does not require confirmation (`require_confirmation=false`), the consumption will be finalized and an actual transaction will be generated.

5. If a confirmation is required (for example, Alice was sending money and wants to see who is trying to get her money and approve it), Alice's app needs to be listening to websocket events. By joining the websocket channel `transaction_request:{alice_transaction_request_id}`, she will receive events such as `transaction_consumption_request`. When receiving those events, she can then [approve](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/approve_transaction_consumption) or [reject](https://ewallet.demo.omisego.io/api/docs.ui#/TransactionRequest/reject_transaction_consumption) it.

6. Bob's app should be listening to the `transaction_consumption:{bob_consumption_id}` in order to know if it was approved or rejected by Alice. He will receive a `transaction_consumption_finalized` with either a confirmed consumption, or a rejected one (or potentially a failed one if the sender didn't have enough funds).

You can check the [Websocket docs](/docs/websockets/ewallet_api.md) for more details on the available events.
