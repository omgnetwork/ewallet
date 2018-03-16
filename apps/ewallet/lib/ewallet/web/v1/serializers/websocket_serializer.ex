defmodule EWallet.Web.V1.WebsocketResponseSerializer do
  @moduledoc """
  Serializes websocket data into V1 response format.
  """
  @behaviour Phoenix.Transports.Serializer

  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast

  @doc """
  Renders the given `data` into a V1 response format as JSON.
  """
  def serialize(data, %{
    success: success,
    topic: topic,
    event: event
  } = attrs) do
    %{
      success: success,
      version: "1",
      data: data,
      topic: topic,
      event: event,
      ref: attrs["ref"]
    }
  end

  @doc """
  Translates a `Phoenix.Socket.Broadcast` into a `Phoenix.Socket.Message`.
  """
  def fastlane!(%Broadcast{} = msg) do
    msg = %Message{topic: msg.topic, event: msg.event, payload: msg.payload}
    {:socket_push, :text, encode_fields(msg)}
  end

  @doc """
  Encodes a `Phoenix.Socket.Message` struct to JSON string.
  """
  def encode!(%Reply{} = reply) do
    msg = %Message{
      topic: reply.topic,
      event: "phx_reply",
      ref: reply.ref,
      payload: %{status: reply.status, response: reply.payload}
    }

    {:socket_push, :text, encode_fields(msg)}
  end
  def encode!(%Message{} = msg) do
    {:socket_push, :text, encode_fields(msg)}
  end

  @doc """
  Decodes JSON String into `Phoenix.Socket.Message` struct.
  """
  def decode!(message, _opts) do
    message
    |> Poison.decode!()
    |> Phoenix.Socket.Message.from_map!()
  end

  defp encode_fields(%Message{} = msg) do
    msg.payload
    |> serialize(%{success: true, topic: msg.topic, event: msg.event, payload: msg.payload})
    |> Poison.encode_to_iodata!()
  end
end
