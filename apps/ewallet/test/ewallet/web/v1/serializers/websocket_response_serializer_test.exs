# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Web.V1.WebsocketResponseSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.WebsocketResponseSerializer
  alias Phoenix.Socket.{Broadcast, Message, Reply}

  describe "serialize/1" do
    test "serializes a websocket message" do
      msg = %Message{ref: 1, topic: "topic", event: "event"}

      res =
        WebsocketResponseSerializer.serialize(%{
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

  describe "encode!/1 with %Broadcast{}" do
    test "encodes fields" do
      msg = %Broadcast{
        topic: "topic",
        event: "event",
        payload: %{
          status: :ok,
          data: %{}
        }
      }

      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(msg)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
               "data" => %{},
               "error" => nil,
               "event" => "event",
               "ref" => nil,
               "success" => true,
               "topic" => "topic",
               "version" => "1"
             }
    end
  end

  describe "encode!/1 with %Message{}" do
    test "encodes fields" do
      msg = %Message{
        ref: 1,
        topic: "topic",
        event: "event",
        payload: %{
          status: :ok,
          data: %{}
        }
      }

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
      reply = %Reply{ref: 1, topic: "topic", status: :ok, payload: %{data: %{}}}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
               "data" => %{},
               "error" => nil,
               "event" => "phx_reply",
               "ref" => 1,
               "success" => true,
               "topic" => "topic",
               "version" => "1"
             }
    end

    test "encodes phx_reply with reason" do
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

    test "encodes phx_reply with code" do
      reply = %Reply{ref: 1, topic: "topic", status: :error, payload: :forbidden_channel}

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

    test "encodes phx_reply with empty payload" do
      reply = %Reply{ref: 1, topic: "topic", status: :ok, payload: %{}}
      {:socket_push, :text, encoded} = WebsocketResponseSerializer.encode!(reply)
      decoded = Poison.decode!(encoded)

      assert decoded == %{
               "data" => nil,
               "error" => nil,
               "event" => "phx_reply",
               "ref" => 1,
               "success" => true,
               "topic" => "topic",
               "version" => "1"
             }
    end
  end
end
