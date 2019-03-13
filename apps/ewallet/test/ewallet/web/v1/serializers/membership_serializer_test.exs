# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.MembershipSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.MembershipSerializer
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Orchestrator, V1.MembershipOverlay}
  alias EWalletDB.{User, Membership}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  describe "serialize/1" do
    test "serializes a membership into user json" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      role = insert(:role)
      {:ok, membership} = Membership.assign(user, account, role, %System{})
      {:ok, membership} = Orchestrator.one(membership, MembershipOverlay)

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
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        encrypted_metadata: %{},
        avatar: %{
          original: nil,
          large: nil,
          small: nil,
          thumb: nil
        },
        created_at: DateFormatter.to_iso8601(user.inserted_at),
        updated_at: DateFormatter.to_iso8601(user.updated_at),
        account_role: role.name,
        status: User.get_status(user),
        account: %{
          avatar: %{large: nil, original: nil, small: nil, thumb: nil},
          categories: %{data: [], object: "list"},
          category_ids: [],
          description: account.description,
          encrypted_metadata: %{},
          id: account.id,
          master: false,
          metadata: %{},
          name: account.name,
          object: "account",
          parent_id: nil,
          socket_topic: "account:#{account.id}",
          created_at: DateFormatter.to_iso8601(account.inserted_at),
          updated_at: DateFormatter.to_iso8601(account.updated_at)
        }
      }

      assert MembershipSerializer.serialize(membership) == expected
    end

    test "serializes to nil if membership is not given" do
      assert MembershipSerializer.serialize(nil) == nil
    end

    test "serializes to nil if membership is not loaded" do
      assert MembershipSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes a list of memberships into a list of users json" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      role = insert(:role)
      {:ok, membership} = Membership.assign(user, account, role, %System{})
      {:ok, membership} = Orchestrator.one(membership, MembershipOverlay)

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
        full_name: user.full_name,
        calling_name: user.calling_name,
        socket_topic: "user:#{user.id}",
        provider_user_id: user.provider_user_id,
        email: user.email,
        enabled: user.enabled,
        metadata: %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        encrypted_metadata: %{},
        avatar: %{
          original: nil,
          large: nil,
          small: nil,
          thumb: nil
        },
        created_at: DateFormatter.to_iso8601(user.inserted_at),
        updated_at: DateFormatter.to_iso8601(user.updated_at),
        account_role: role.name,
        status: User.get_status(user),
        account: %{
          avatar: %{large: nil, original: nil, small: nil, thumb: nil},
          categories: %{data: [], object: "list"},
          category_ids: [],
          description: account.description,
          encrypted_metadata: %{},
          id: account.id,
          master: false,
          metadata: %{},
          name: account.name,
          object: "account",
          parent_id: nil,
          socket_topic: "account:#{account.id}",
          created_at: DateFormatter.to_iso8601(account.inserted_at),
          updated_at: DateFormatter.to_iso8601(account.updated_at)
        }
      }

      assert MembershipSerializer.serialize(membership) == expected
    end
  end
end
