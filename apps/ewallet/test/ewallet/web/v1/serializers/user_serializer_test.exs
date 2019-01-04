# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.UserSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.UserSerializer

  describe "serialize/1" do
    test "serializes a user into correct JSON format" do
      user = insert(:user)

      expected = %{
        object: "user",
        id: user.id,
        socket_topic: "user:#{user.id}",
        username: user.username,
        full_name: user.full_name,
        calling_name: user.calling_name,
        provider_user_id: user.provider_user_id,
        email: user.email,
        enabled: user.enabled,
        avatar: %{
          original: nil,
          large: nil,
          small: nil,
          thumb: nil
        },
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        encrypted_metadata: %{},
        created_at: Date.to_iso8601(user.inserted_at),
        updated_at: Date.to_iso8601(user.updated_at)
      }

      assert UserSerializer.serialize(user) == expected
    end

    test "serializes to nil if user is not given" do
      assert UserSerializer.serialize(nil) == nil
    end

    test "serializes to nil if user is not loaded" do
      assert UserSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes a user paginator into a list object" do
      user1 = insert(:user)
      user2 = insert(:user)

      paginator = %Paginator{
        data: [user1, user2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "user",
            id: user1.id,
            socket_topic: "user:#{user1.id}",
            username: user1.username,
            full_name: user1.full_name,
            calling_name: user1.calling_name,
            provider_user_id: user1.provider_user_id,
            email: user1.email,
            avatar: %{
              original: nil,
              large: nil,
              small: nil,
              thumb: nil
            },
            enabled: user1.enabled,
            metadata: %{
              "first_name" => user1.metadata["first_name"],
              "last_name" => user1.metadata["last_name"]
            },
            encrypted_metadata: %{},
            created_at: Date.to_iso8601(user1.inserted_at),
            updated_at: Date.to_iso8601(user1.updated_at)
          },
          %{
            object: "user",
            id: user2.id,
            socket_topic: "user:#{user2.id}",
            username: user2.username,
            full_name: user2.full_name,
            calling_name: user2.calling_name,
            provider_user_id: user2.provider_user_id,
            email: user2.email,
            avatar: %{
              original: nil,
              large: nil,
              small: nil,
              thumb: nil
            },
            enabled: user2.enabled,
            metadata: %{
              "first_name" => user2.metadata["first_name"],
              "last_name" => user2.metadata["last_name"]
            },
            encrypted_metadata: %{},
            created_at: Date.to_iso8601(user2.inserted_at),
            updated_at: Date.to_iso8601(user2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert UserSerializer.serialize(paginator) == expected
    end

    test "serializes a list of users into a list object" do
      user1 = insert(:user)
      user2 = insert(:user)

      users = [user1, user2]

      expected = %{
        object: "list",
        data: [
          %{
            object: "user",
            id: user1.id,
            socket_topic: "user:#{user1.id}",
            username: user1.username,
            full_name: user1.full_name,
            calling_name: user1.calling_name,
            provider_user_id: user1.provider_user_id,
            email: user1.email,
            avatar: %{
              original: nil,
              large: nil,
              small: nil,
              thumb: nil
            },
            metadata: %{
              "first_name" => user1.metadata["first_name"],
              "last_name" => user1.metadata["last_name"]
            },
            encrypted_metadata: %{},
            enabled: user1.enabled,
            created_at: Date.to_iso8601(user1.inserted_at),
            updated_at: Date.to_iso8601(user1.updated_at)
          },
          %{
            object: "user",
            id: user2.id,
            socket_topic: "user:#{user2.id}",
            username: user2.username,
            full_name: user2.full_name,
            calling_name: user2.calling_name,
            provider_user_id: user2.provider_user_id,
            email: user2.email,
            avatar: %{
              original: nil,
              large: nil,
              small: nil,
              thumb: nil
            },
            metadata: %{
              "first_name" => user2.metadata["first_name"],
              "last_name" => user2.metadata["last_name"]
            },
            encrypted_metadata: %{},
            enabled: user2.enabled,
            created_at: Date.to_iso8601(user2.inserted_at),
            updated_at: Date.to_iso8601(user2.updated_at)
          }
        ]
      }

      assert UserSerializer.serialize(users) == expected
    end
  end

  describe "serialize/2" do
    test "serializes users to ids" do
      users = [user1, user2] = insert_list(2, :user)
      assert UserSerializer.serialize(users, :id) == [user1.id, user2.id]
    end
  end
end
