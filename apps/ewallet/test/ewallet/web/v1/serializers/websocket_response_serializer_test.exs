defmodule EWallet.Web.V1.WebsocketResponseSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.WebsocketResponseSerializer
  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message

  describe "serialize/3" do
    test "serializes a websocket message" do
      msg = %Message{ref: 1, topic: "topic", event: "event"}
      res = WebsocketResponseSerializer.serialize(%{something: "cool"}, msg, true)

      assert res == %{
        event: "event",
        ref: 1,
        success: true,
        topic: "topic",
        version: "1",
        data: %{something: "cool"}
      }
    end
  end

  describe "encode!/1 with %Message{}" do
    test "encodes fields" do
      msg = %Message{ref: 1, topic: "topic", event: "event", payload: %{}}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(msg)
      decoded = Poison.decode!(encoded)
      # refute true
      assert decoded == %{
        "data" => %{},
        "event" => "event",
        "ref" => 1,
        "success" => true,
        "topic" => "topic",
        "version" => "1"
      }
    end
  end

  describe "encode!/1 with %Reply{}" do
    test "encodes phx_reply succesfully" do
      reply = %Reply{ref: 1, topic: "topic", status: :ok, payload: %{}}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
        "data" => %{},
        "event" => "phx_reply",
        "ref" => 1,
        "success" => true,
        "topic" => "topic",
        "version" => "1"
      }
    end

    test "fails to encode phx_reply with reason" do
      reply = %Reply{ref: 1, topic: "topic", status: :error, payload: %{reason: "something"}}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
        "data" => %{
          "code" => "websocket:connect_error",
          "description" => "something",
          "messages" => nil,
          "object" => "error"
        },
        "event" => "phx_reply",
        "ref" => 1,
        "success" => false,
        "topic" => "topic",
        "version" => "1"
      }
    end

    test "fails to encode phx_reply with code" do
      reply = %Reply{ref: 1, topic: "topic", status: :error, payload: :forbidden_channel}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
        "data" => %{
          "code" => "websocket:forbidden_channel",
          "description" => "You don't have access to this channel.",
          "messages" => nil,
          "object" => "error"
        },
        "event" => "phx_reply",
        "ref" => 1,
        "success" => false,
        "topic" => "topic",
        "version" => "1"
      }
    end
  end
end
