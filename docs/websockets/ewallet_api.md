# eWallet API Websockets

The eWallet API offers a websocket interface for real-time communication. Currently, it can only be used to receive events. If you're planning to use the transaction requests with the `require_confirmation`, websockets are the best way to handle the confirmations in a safe way.

## Getting Started

Before diving into the details of how websockets can be used, here is a sample flow. First, we initialize a socket connection and join a channel. Then, we wait for an event to be received before leaving the channel.

1. Initialize socket connection by sending a request to `/api/socket`.

2. Join a channel (`"transaction_request:some_id"`)

Payload sent:
```
{
  "topic": "transaction_request:some_id",
  "event": "phx_join",
  "ref": "1",
  "data": {}
}
```

Payload from server:
```
{
  "success": true,
  "version": "1",
  "data": null,
  "error": null,
  "topic": "transaction_request:some_id",
  "event": "phx_reply",
  "ref": "1"
}
```

3. Wait for events

Payload from server:
```
{
  "success": true,
  "version": "1",
  "data": {
    # consumption data
  },
  "error": null,
  "topic": "transaction_request:some_id",
  "event": "transaction_consumption_finalized",
  "ref": null
}
```

4. Leave a channel

Payload sent:
```
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "2",
  "data": {}
}
```

Payload from server:
```
{
  "success": true,
  "version": "1",
  "data": null,
  "error": null,
  "topic": "transaction_request:some_id",
  "event": "phx_reply",
  "ref": "2"
}
```

Now, let's learn more about each step.

## Connecting to the websocket interface

The websocket interface of the eWallet API is available at `/api/socket`. Use the websocket protocol (with SSL, `wss`) to connect.

Full URL:
```
wss://EWALLET_URL/api/socket
```

Example URL:
```
wss://ewallet.demo.omisego.io/api/socket
```

__If you're not using a library, you will need to send a `GET` HTTP request with the appropriate headers to upgrade it into a websocket connection See [here](https://tools.ietf.org/html/rfc6455#section-1.3) for more details.__

In order to connect to a websocket, you must provide the same `Authorization` header you would for the [eWallet HTTP API](https://ewallet.demo.omisego.io/api/docs.ui):

For authentication from servers:
```
Authorization: OMGServer base64(access_key:secret_key)
```

From clients:
```
Authorization: OMGClient base64(api_key:authentication_token)
```

The `Accept` header also needs to be set to the appropriate media type (replace `v1` with the version you want to use):

```
Accept: application/vnd.omisego.v1+json
```

Not sending valid headers will result in the request failing and the server returning some kind of invalid HTTP upgrade error.

## Joining a channel

Channels can be joined by sending the `phx_join` event. The list of events is available below. Joining allows you to listen to its events and, later on, send requests to retrieve data.

## Listening for events

Events for a specified chahnel will be sent to everyone who joined the channel. See list of channels and potential events below.

## Leaving a channel

To leave a channel, simply send the `phx_leave` event.

Payload sent:
```
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "1",
  "data": {}
}
```

## Keeping the connection alive (hearbeat)

In order to keep the socket connection alive, you can periodically send heartbeats using the following payload.

Payload sent:
```
{
  "topic": "phoenix",
  "event": "heartbeat",
  "ref": "1",
  "data": {}
}
```

## Channels

The following channels are available in the eWallet API:

### `account:{id}`

All events related to the specified account will be sent to that channel.

Potential events:

- `transaction_consumption_request`
- `transaction_consumption_finalized`

### `user:{id}`

All events related to the specified user will be sent to that channel.

Potential events:

- `transaction_consumption_request`
- `transaction_consumption_finalized`

### `address:{address}`

All events related to the specified address will be sent to that channel.

Potential events:

- `transaction_consumption_request`
- `transaction_consumption_finalized`

### `transaction_request:{id}`

All events related to the specified transaction request will be sent to that channel.

Potential events:

- `transaction_consumption_request`
- `transaction_consumption_finalized`

### `transaction_consumption:{id}`

All events related to the specified consumption will be sent to that channel.

Potential events:

- `transaction_consumption_finalized`

## Events

### Sendable events

- `phx_join`: event used to join a channel.

```
{
  "topic": "transaction_request:some_id",
  "event": "phx_join",
  "ref": "1",
  "data": {}
}
```

- `phx_leave`: event used to leave a channel.

```
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "2",
  "data": {}
}
```

- `heartbeat`: event used to keep the connection open.

```
{
  "topic": "phoenix",
  "event": "heartbeat",
  "ref": "1",
  "data": {}
}
```

### Receivable system events

- `phx_error`: event sent by the server in case something goes wrong while connecting to a channel for example.

- `phx_reply`: event sent as a reply to a client-emitted event.

- `phx_close`: event sent by the server when the client requests to terminate the connection.

### Receivable custom events

#### Success vs failure

The following events can contain either some `data` if `success` is true, or an `error` if `success` is false. For example, when sending the `transaction_consumption_finalized`, it is possible to receive the finalized consumption OR an error stating that it was finalized in a failed state because there were not enough funds for the actual transaction to proceed.

#### Events

- `transaction_consumption_request`:

```
{
  "success": true,
  "version": "1",
  "data": {
    "object": "transaction_consumption",
    "id": "txc_123",
    "socket_topic": "transaction_consumption:txc_123",
    "amount": 1000,
    "minted_token_id": "tok_124",
    "minted_token": { # serialized minted token },
    "correlation_id": "123456",
    "idempotency_token": "some_idempotency_token",
    "transaction_id": "tfr_890",
    "transaction": { # serialized transaction },
    "user_id": "usr_347"
    "user": { # serialized user },
    "account_id": "acc_3292",
    "account": { # serialized account },
    "transaction_request_id": consumption.transaction_request.id,
    "address": consumption.balance_address,
    "metadata": consumption.metadata,
    "encrypted_metadata": consumption.encrypted_metadata,
    "expiration_date": Date.to_iso8601(consumption.expiration_date),
    "status": consumption.status,
    "approved_at": Date.to_iso8601(consumption.approved_at),
    "rejected_at": Date.to_iso8601(consumption.rejected_at),
    "confirmed_at": Date.to_iso8601(consumption.confirmed_at),
    "failed_at": Date.to_iso8601(consumption.failed_at),
    "expired_at": Date.to_iso8601(consumption.expired_at),
    "created_at": Date.to_iso8601(consumption.inserted_at)
  },
  "error": nil,
  "topic": "transaction_request:some_id",
  "event": "transaction_consumption_request",
  "ref": "1"
}
```

- `transaction_consumption_finalized`:


```

```
