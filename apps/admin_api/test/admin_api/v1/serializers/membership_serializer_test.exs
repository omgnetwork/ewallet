defmodule AdminAPI.V1.MembershipSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias AdminAPI.V1.{MembershipOverlay, MembershipSerializer}
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Orchestrator}
  alias EWalletDB.User

  describe "serialize/1" do
    test "serializes a membership into user json" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      role = insert(:role)
      membership = insert(:membership, %{account: account, user: user, role: role})
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
        created_at: Date.to_iso8601(user.inserted_at),
        updated_at: Date.to_iso8601(user.updated_at),
        account_role: role.name,
        status: User.get_status(user),
        account: %{
          avatar: %{large: nil, original: nil, small: nil, thumb: nil},
          categories: %{data: [], object: "list"},
          category_ids: [],
          description: account.description,
          encrypted_metadata: %{},
          id: account.id,
          master: true,
          metadata: %{},
          name: account.name,
          object: "account",
          parent_id: nil,
          socket_topic: "account:#{account.id}",
          created_at: Date.to_iso8601(account.inserted_at),
          updated_at: Date.to_iso8601(account.updated_at)
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
      membership = insert(:membership, %{account: account, user: user, role: role})
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
        created_at: Date.to_iso8601(user.inserted_at),
        updated_at: Date.to_iso8601(user.updated_at),
        account_role: role.name,
        status: User.get_status(user),
        account: %{
          avatar: %{large: nil, original: nil, small: nil, thumb: nil},
          categories: %{data: [], object: "list"},
          category_ids: [],
          description: account.description,
          encrypted_metadata: %{},
          id: account.id,
          master: true,
          metadata: %{},
          name: account.name,
          object: "account",
          parent_id: nil,
          socket_topic: "account:#{account.id}",
          created_at: Date.to_iso8601(account.inserted_at),
          updated_at: Date.to_iso8601(account.updated_at)
        }
      }

      assert MembershipSerializer.serialize(membership) == expected
    end
  end
end
