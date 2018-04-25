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

- "phx_join"
- "phx_leave"
- "heartbeat"

### Receivable events

- "phx_error"
- "phx_reply"
- "phx_close"

- "transaction_consumption_request"
- "transaction_consumption_finalized"
