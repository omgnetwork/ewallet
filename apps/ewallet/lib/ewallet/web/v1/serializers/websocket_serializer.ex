defmodule EWallet.Web.V1.WebsocketResponseSerializer do
  @moduledoc """
  Serializes websocket data into V1 response format.
  """
  @behaviour Phoenix.Transports.Serializer

  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast
  alias EWallet.Web.V1.ErrorSerializer

  @doc """
  Renders the given `data` into a V1 response format as JSON.
  """
  def serialize(data, %{
    success: success,
    topic: topic,
    event: event,
    ref: ref
  }) do
    %{
      success: success,
      version: "1",
      data: data,
      topic: topic,
      event: event,
      ref: ref
    }
  end

  @doc """
  Translates a `Phoenix.Socket.Broadcast` into a `Phoenix.Socket.Message`.
  """
  def fastlane!(%Broadcast{} = msg) do
    msg = %Message{
      topic: msg.topic,
      event: msg.event,
      payload: %{
        status: :ok,
        data: msg.payload
      }
    }

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
      payload: %{status: reply.status, data: reply.payload}
    }

    {:socket_push, :text, encode_fields(msg)}
  end
  def encode!(%Message{} = msg) do
    msg = %Message{
      topic: msg.topic,
      event: msg.event,
      ref: msg.ref,
      payload: %{status: :ok, data: msg.payload}
    }

    {:socket_push, :text, encode_fields(msg)}
  end

  @doc """
  Decodes JSON String into `Phoenix.Socket.Message` struct.
  """
  def decode!(message, _opts) do
    decoded = Poison.decode!(message)

    decoded
    |> Map.put("payload", decoded["data"])
    |> Message.from_map!()
  end

  defp encode_fields(%Message{} = msg) do
    case msg.payload.status do
      :ok ->
        msg.payload.data
        |> serialize(%{
          success: true,
          ref: msg.ref,
          topic: msg.topic,
          event: msg.event
        })
        |> Poison.encode_to_iodata!()
      :error ->
        "websocket:connect_error"
        |> ErrorSerializer.serialize(msg.payload.data.reason)
        |> serialize(%{
          success: false,
          ref: msg.ref,
          topic: msg.topic,
          event: msg.event
        })
        |> Poison.encode_to_iodata!()
    end

  end
end
