defmodule EWallet.Web.V1.WebsocketResponseSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.WebsocketResponseSerializer
  alias Phoenix.Socket.Reply
  alias Phoenix.Socket.Message

  describe "serialize/1" do
    test "serializes a websocket message" do
      msg = %Message{ref: 1, topic: "topic", event: "event"}
      res = WebsocketResponseSerializer.serialize(%{
        data: %{something: "cool"},
        error: nil,
        msg: msg,
        success: true
      })

      assert res == %{
        event: "event",
        ref: 1,
        success: true,
        topic: "topic",
        version: "1",
        data: %{something: "cool"},
        error: nil
      }
    end
  end

  describe "encode!/1 with %Message{}" do
    test "encodes fields" do
      msg = %Message{ref: 1, topic: "topic", event: "event", payload: %{
        status: :ok,
        data: %{}
      }}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(msg)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
        "data" => %{},
        "error" => nil,
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
        "data" => nil,
        "error" => nil,
        "event" => "phx_reply",
        "ref" => 1,
        "error" => nil,
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
        "data" => nil,
        "error" => %{
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
      reply = %Reply{ref: 1, topic: "topic", status: :error, payload: %{
        error_code: :forbidden_channel
      }}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
        "data" => nil,
        "error" => %{
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
