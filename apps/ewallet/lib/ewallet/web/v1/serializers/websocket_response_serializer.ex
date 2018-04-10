defmodule EWallet.Web.V1.WebsocketResponseSerializer do
  @moduledoc """
  Serializes websocket data into V1 response format.
  """
  @behaviour Phoenix.Transports.Serializer

  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message
  alias Phoenix.Socket.Broadcast
  alias EWallet.Web.V1.ErrorHandler

  @doc """
  Renders the given `data` into a V1 response format as JSON.
  """
  def serialize(%{
     data: data,
     error: error,
     msg: msg,
     success: success
  }) do
    %{
      success: success,
      version: "1",
      data: data,
      error: error,
      topic: msg.topic,
      event: msg.event,
      ref: msg.ref
    }
  end

  @doc """
  Translates a `Phoenix.Socket.Broadcast` into a `Phoenix.Socket.Message`.
  """
  def fastlane!(%Broadcast{} = msg) do
    IO.inspect("Broadcast")
    IO.inspect(msg)
    msg = %Message{
      topic: msg.topic,
      event: msg.event,
      payload: msg.payload
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
      payload: reply.payload |> Map.put(:status, reply.status)
    }

    {:socket_push, :text, encode_fields(msg)}
  end
  def encode!(%Message{} = msg) do
    msg = %Message{
      topic: msg.topic,
      event: msg.event,
      ref: msg.ref,
      payload: msg.payload
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

  defp encode_fields(%Message{payload: %{status: :ok, data: data}} = msg) do
    %{
      data: data,
      error: nil,
      msg: msg,
      success: true
    }
    |> serialize()
    |> Poison.encode_to_iodata!()
  end

  defp encode_fields(%Message{payload: %{status: :error, data: %{reason: reason}}} = msg) do
    :websocket_connect_error
    |> ErrorHandler.build_error(reason, nil)
    |> encode_error(msg)
  end

  defp encode_fields(%Message{payload: %{status: :error, error_code: code, data: data}} = msg)
  when is_atom(code)
  when is_binary(code)
  do
    code
    |> ErrorHandler.build_error(nil, data)
    |> encode_error(msg)
  end

  defp encode_error(error, msg, data \\ nil) do
    %{
      data: data,
      error: error,
      msg: msg,
      success: false
    }
    |> serialize()
    |> Poison.encode_to_iodata!()
  end
end
