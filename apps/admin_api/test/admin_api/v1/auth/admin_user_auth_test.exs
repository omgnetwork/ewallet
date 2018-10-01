defmodule AdminAPI.Web.V1.AdminUserAuthTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminUserAuth
  alias EWalletDB.{AuthToken, User}

  def auth_header(user_id, token) do
    encoded_key = Base.encode64(user_id <> ":" <> token)
    AdminUserAuth.authenticate(%{auth_header: "OMGAdmin #{encoded_key}"})
  end

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()

    %{
      user: user,
      auth_token: insert(:auth_token, user: user, owner_app: "admin_api")
    }
  end

  describe "authenticate/1" do
    test "returns authenticated: true when given valid user_id/token", meta do
      auth = auth_header(meta.user.id, meta.auth_token.token)

      assert auth.authenticated == true
      assert auth.admin_user.uuid == meta.user.uuid
      assert auth.auth_user_id == meta.user.id
      assert auth.auth_auth_token == meta.auth_token.token
    end

    test "returns authenticated: false when given invalid user_id", meta do
      auth = auth_header("fake_id", meta.auth_token.token)

      assert auth.authenticated == false
      assert auth.auth_error == :auth_token_not_found

      assert auth[:admin_user] == nil
      assert auth[:auth_user_id] == "fake_id"
      assert auth[:auth_auth_token] == meta.auth_token.token
    end

    test "returns authenticated: false when given invalid token", meta do
      auth = auth_header(meta.user.id, "fake_token")

      assert auth.authenticated == false
      assert auth.auth_error == :auth_token_not_found

      assert auth[:admin_user] == nil
      assert auth[:auth_user_id] == meta.user.id
      assert auth[:auth_auth_token] == "fake_token"
    end

    test "returns authenticated: false when given expired token", meta do
      auth_token = insert(:auth_token, user: meta.user, owner_app: "admin_api")
      AuthToken.expire(auth_token.token, :admin_api)
      auth = auth_header(meta.user.id, auth_token.token)

      assert auth.authenticated == false
      assert auth.auth_error == :auth_token_expired

      assert auth[:admin_user] == nil
      assert auth[:auth_user_id] == meta.user.id
      assert auth[:auth_auth_token] == auth_token.token
    end

    test "returns authenticated: false when given invalid auth scheme", meta do
      encoded_key = Base.encode64(meta.user.id <> ":" <> meta.auth_token.token)
      auth = AdminUserAuth.authenticate(%{auth_header: "FAKEAdmin #{encoded_key}"})

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_auth_scheme

      assert auth[:admin_user] == nil
      assert auth[:auth_user_id] == nil
      assert auth[:auth_auth_token] == nil
    end
  end
end
