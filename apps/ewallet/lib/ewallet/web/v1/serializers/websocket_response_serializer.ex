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

    case decoded do
      %{} = decoded ->
        decoded
        |> Map.put("payload", decoded["data"])
        |> Message.from_map!()
      [join_ref, ref, topic, event, payload | _] ->
        %{
          "topic" => topic,
          "event" => event,
          "ref" => ref,
          "join_ref" => join_ref,
          "payload" => payload
        }
        |> Message.from_map!()
    end
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

  defp encode_fields(%{reason: reason} = msg) when not is_nil(reason) do
    encode_fields(msg, build_reason(msg.reason))
  end

  defp encode_fields(msg) do
    encode_fields(msg, build_error(msg.error))
  end

  defp encode_fields(msg, error) do
    %{
      data: msg.data,
      error: error,
      msg: msg,
      success: msg.status == :ok
    }
    |> serialize()
    |> Poison.encode_to_iodata!()
  end

  defp build_error(nil), do: nil
  defp build_error(%{code: nil}), do: nil

  defp build_error(%{code: code, description: description}) do
    ErrorHandler.build_error(code, description, nil)
  end

  defp build_error(%{code: code}), do: ErrorHandler.build_error(code, nil)

  defp build_error(code) when is_atom(code) do
    ErrorHandler.build_error(code, nil)
  end

  defp build_error(_), do: nil

  defp build_reason(nil), do: nil

  defp build_reason(reason) do
    ErrorHandler.build_error(:websocket_connect_error, reason, nil)
  end
end
