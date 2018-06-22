defmodule AdminAPI.V1.ProviderAuthSelfControllerTest do
  use AdminAPI.ConnCase, async: true
  import Ecto.Query
  alias EWalletDB.{Membership, Repo}

  describe "/me.get" do
    test "gets access_key:unauthorized back" do
      response = provider_request("/me.get")

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.update" do
    test "gets access_key:unauthorized back" do
      response =
        provider_request("/me.update", %{
          email: "test_1337@example.com",
          metadata: %{"key" => "value_1337"},
          encrypted_metadata: %{"key" => "value_1337"}
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.upload_avatar" do
    test "gets access_key:unauthorized back" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = get_test_admin()
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response =
        provider_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.get_account" do
    test "gets access_key:unauthorized back" do
      response = provider_request("/me.get_account")

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.get_accounts" do
    test "gets access_key:unauthorized back" do
      user = get_test_admin()
      parent = insert(:account)
      account = insert(:account, %{parent: parent})

      # Clear all memberships for this user then add just one for precision
      Repo.delete_all(from(m in Membership, where: m.user_uuid == ^user.uuid))
      Membership.assign(user, account, "admin")

      response =  provider_request("/me.get_accounts")

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end
end
