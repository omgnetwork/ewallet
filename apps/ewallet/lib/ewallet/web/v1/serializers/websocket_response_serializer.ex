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
    msg = msg |> build_message() |> encode_fields()
    {:socket_push, :text, msg}
  end

  @doc """
  Encodes a `Phoenix.Socket.Message` struct to JSON string.
  """
  def encode!(msg) do
    msg = msg |> build_message() |> encode_fields()
    {:socket_push, :text, msg}
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

  defp build_message(%Reply{} = reply) do
    case is_atom(reply.payload) do
      true ->
        reply
        |> Map.put(:payload, %{
          error: reply.payload,
          data: nil,
          reason: nil
        })
        |> format()

      false ->
        format(reply)
    end
  end

  defp build_message(msg), do: format(msg)

  defp format(data) do
    data = Map.from_struct(data)

    %{
      topic: data[:topic],
      event: data[:event] || "phx_reply",
      ref: data[:ref] || nil,
      status: data[:status] || data[:payload][:status],
      data: data[:payload][:data],
      error: data[:payload][:error],
      reason: data[:payload][:reason]
    }
  end

  defp encode_fields(msg) do
    %{
      data: msg.data,
      error: build_error(msg.error, msg.reason),
      msg: msg,
      success: msg.status == :ok
    }
    |> serialize()
    |> Poison.encode_to_iodata!()
  end

  defp build_error(nil, nil), do: nil

  defp build_error(nil, reason) do
    ErrorHandler.build_error(:websocket_connect_error, reason, nil)
  end

  defp build_error(code, nil) when is_atom(code) when is_binary(code) do
    ErrorHandler.build_error(code, nil)
  end
end
