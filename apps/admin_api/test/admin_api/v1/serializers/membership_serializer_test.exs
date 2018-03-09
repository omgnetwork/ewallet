defmodule AdminAPI.V1.MembershipSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias AdminAPI.V1.MembershipSerializer
  alias EWallet.Web.Date
  alias EWalletDB.User

  describe "to_user_json/1" do
    test "serializes a membership into user json" do
      account    = insert(:account)
      user       = insert(:user)
      role       = insert(:role)
      membership = insert(:membership, %{account: account, user: user, role: role})

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
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
        status: User.get_status(user)
      }

      assert MembershipSerializer.to_user_json(membership) == expected
    end

    test "serializes a list of memberships into a list of users json" do
      account    = insert(:account)
      user       = insert(:user)
      role       = insert(:role)
      membership = insert(:membership, %{account: account, user: user, role: role})

      expected = %{
        object: "user",
        id: user.id,
        username: user.username,
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
        status: User.get_status(user)
      }

      assert MembershipSerializer.to_user_json(membership) == expected
    end
  end
end
