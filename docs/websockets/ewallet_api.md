# eWallet API Websockets

The eWallet API offers a websocket interface for real-time communication. Currently, it can only be used to receive events. If you're planning to use the transaction requests with the `require_confirmation`, websockets are the best way to handle the confirmations in a safe way.

## Getting Started

Before diving into the details of how websockets can be used, here is a sample flow. First, we initialize a socket connection and join a channel. Then, we wait for an event to be received before leaving the channel.

1. Initialize socket connection by sending a request to `/api/client/socket`.

2. Join a channel (`"transaction_request:some_id"`)

Payload sent:
```json
{
  "topic": "transaction_request:some_id",
  "event": "phx_join",
  "ref": "1",
  "data": {}
}
```

Payload from server:
```json
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
```json
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
```json
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "2",
  "data": {}
}
```

Payload from server:
```json
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

The websocket interface of the eWallet API is available at `/api/client/socket`. Use the websocket protocol (with SSL, `wss`) to connect.

Full URL:
```
wss://EWALLET_URL/api/client/socket
```

Example URL:
```
wss://ewallet.demo.omisego.io/api/client/socket
```

__If you're not using a library, you will need to send a `GET` HTTP request with the appropriate headers to upgrade it into a websocket connection See [here](https://tools.ietf.org/html/rfc6455#section-1.3) for more details.__

In order to connect to a websocket, you must provide the same `Authorization` header you would for the [eWallet HTTP API](https://ewallet.demo.omisego.io/api/client/docs.ui):

For authentication from servers:
```
Authorization: OMGProvider base64(access_key:secret_key)
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

Events for a specified channel will be sent to everyone who joined the channel. See list of channels and potential events below.

## Leaving a channel

To leave a channel, simply send the `phx_leave` event.

Payload sent:
```json
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "1",
  "data": {}
}
```

## Keeping the connection alive (heartbeat)

In order to keep the socket connection alive, you can periodically send heartbeats using the following payload.

Payload sent:
```json
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

## Errors

The potential errors are listed [here](https://ewallet.demo.omisego.io/api/client/errors.ui).

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

```json
{
  "topic": "transaction_request:some_id",
  "event": "phx_leave",
  "ref": "2",
  "data": {}
}
```

- `heartbeat`: event used to keep the connection open.

```json
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

#### Format

Custom events have the following format. It closely follows the usual enveloppe used in the eWallet HTTP APIs with some added attributes related to websockets. Note that those events can either be successful or not.

For example, when sending the `transaction_consumption_finalized`, it is possible to receive the finalized consumption OR an error stating that it was finalized in a failed state because there were not enough funds for the actual transaction to proceed.

- `success` (`boolean`, `true` OR `false`): Defines if the event is the result of a successful action or not.
- `version` (`string`, ex: `"1"`): The websockets API version.
- `data` (`object`): The data relevant to the event. Can be `nil` if `success` is equal to `false` (but could also contain something to provide context for the error). See examples in the events below.
- `error` (`object`): The error resulting from the action generating th event.
  - `code` (`string`): The error code.
  - `description` (`string`): The error description.
  - `messages` (`array`): List of messages related to the error.
  - `object` (`string`, `error`)
- `topic` (`string`): The topic (channel) to which the event was sent (probably the name of the channel you joined).
- `event` (`string`): The name of the event.
- `ref` (`string`): `nil` for events emitted from the server in response to a server action.

#### Events

- `transaction_consumption_request`:

```json
{
  "success": true,
  "version": "1",
  "data": { ... },
  "error": nil,
  "topic": "transaction_request:some_id",
  "event": "transaction_consumption_request",
  "ref": "1"
}
```

Where `data` contains a transaction consumption with the following attributes (stolen from our Swagger spec):

```yaml
object:
  type: string
id:
  type: string
socket_topic:
  type: string
status:
  type: string
  enum:
    - pending
    - approved
    - rejected
    - confirmed
    - failed
    - expired
amount:
  type: string
token_id:
  type: string
token:
  type: object
correlation_id:
  type: string
idempotency_token:
  type: string
transaction_id:
  type: string
transaction:
  type: object
user_id:
  type: string
user:
  type: object
account_id:
  type: string
account:
  type: object
transaction_request_id:
  type: string
transaction_request:
  type: object
address:
  type: string
metadata:
  type: object
encrypted_metadata:
  type: object
expiration_date:
  type: string
created_at:
  type: string
updated_at:
  type: string
approved_at:
  type: string
rejected_at:
  type: string
confirmed_at:
  type: string
failed_at:
  type: string
expired_at:
  type: string
```

Example:

```yaml
{
  object: "transaction_consumption",
  id: "txc_01cbfg9qtdken61agxhx6wvj9h",
  socket_topic: "transaction_consumption:txc_01cbfg9qtdken61agxhx6wvj9h",
  status: "pending",
  amount: 100,
  token_id: "tok_OMG_01cbffwvj6ma9a9gg1tb24880q",
  token: {},
  correlation_id: "7e9c0be5-15d1-4463-9ec2-02bc8ded7120",
  idempotency_token: "7831c0be5-15d1-4463-9ec2-02bc8ded7120",
  transaction_id: "txn_01cbfga8g0dgwcfc7xh6ks1njt",
  transaction: {},
  user_id: "usr_01cbfgak47ng6x72vbwjca6j4v",
  user: {},
  account_id: "acc_01cbfgatsanznvzffqsekta5f0",
  account: {},
  transaction_request_id: "txr_01cbfgb66cby8wp5wpq6n4pm0h",
  transaction_request: {},
  address: "5555cer3-15d1-4463-9ec2-02bc8ded7120",
  metadata: {},
  encrypted_metadata: {},
  expiration_date: null,
  created_at: "2018-01-01T00:00:00Z",
  updated_at: "2018-01-01T00:00:00Z",
  approved_at: null,
  rejected_at: null,
  confirmed_at: null,
  failed_at: null,
  expired_at: null
}
```

- `transaction_consumption_finalized`:

```json
{
  "success": true,
  "version": "1",
  "data": { ... },
  "error": nil,
  "topic": "transaction_request:some_id",
  "event": "transaction_consumption_finalized",
  "ref": "1"
}
```

Where `data` contains a transaction consumption with the following attributes (stolen from our Swagger spec):

```yaml
object:
  type: string
id:
  type: string
socket_topic:
  type: string
status:
  type: string
  enum:
    - pending
    - approved
    - rejected
    - confirmed
    - failed
    - expired
amount:
  type: string
token_id:
  type: string
token:
  type: object
correlation_id:
  type: string
idempotency_token:
  type: string
transaction_id:
  type: string
transaction:
  type: object
user_id:
  type: string
user:
  type: object
account_id:
  type: string
account:
  type: object
transaction_request_id:
  type: string
transaction_request:
  type: object
address:
  type: string
metadata:
  type: object
encrypted_metadata:
  type: object
expiration_date:
  type: string
created_at:
  type: string
updated_at:
  type: string
approved_at:
  type: string
rejected_at:
  type: string
confirmed_at:
  type: string
failed_at:
  type: string
expired_at:
  type: string
```

Example:

```json
{
  "object": "transaction_consumption",
  "id": "txc_01cbfg9qtdken61agxhx6wvj9h",
  "socket_topic": "transaction_consumption:txc_01cbfg9qtdken61agxhx6wvj9h",
  "status": "confirmed",
  "amount": 100,
  "token_id": "tok_OMG_01cbffwvj6ma9a9gg1tb24880q",
  "token": {},
  "correlation_id": "7e9c0be5-15d1-4463-9ec2-02bc8ded7120",
  "idempotency_token": "7831c0be5-15d1-4463-9ec2-02bc8ded7120",
  "transaction_id": "txn_01cbfga8g0dgwcfc7xh6ks1njt",
  "transaction": {},
  "user_id": "usr_01cbfgak47ng6x72vbwjca6j4v",
  "user": {},
  "account_id": "acc_01cbfgatsanznvzffqsekta5f0",
  "account": {},
  "transaction_request_id": "txr_01cbfgb66cby8wp5wpq6n4pm0h",
  "transaction_request": {},
  "address": "5555cer3-15d1-4463-9ec2-02bc8ded7120",
  "metadata": {},
  "encrypted_metadata": {},
  "expiration_date": null,
  "created_at": "2018-01-01T00:00:00Z",
  "updated_at": "2018-01-01T00:00:00Z",
  "approved_at": "2018-01-01T00:00:00Z",
  "rejected_at": null,
  "confirmed_at": "2018-01-01T00:00:00Z",
  "failed_at": null,
  "expired_at": null
}
```
