defmodule AdminAPI.Web.V1.AdminUserAuthenticatorTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminUserAuthenticator
  alias EWalletDB.User
  alias Utils.Helpers.Crypto
  alias ActivityLogger.System

  describe "authenticate/3" do
    test "returns authenticated:true if email and password are valid" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), @user_email, @password)
      assert_success(conn)
    end

    test "returns authenticated:false if the email and password are valid but not an admin" do
      email = "non_admin@example.com"
      password = "some_password"

      _user = insert(:user, %{email: email, password_hash: Crypto.hash_password(password)})
      conn = AdminUserAuthenticator.authenticate(build_conn(), email, password)

      assert_error(conn)
    end

    test "returns authenticated:false if email is invalid" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), "wrong@example.com", @password)
      assert_error(conn)
    end

    test "returns authenticated:false if password is invalid" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), @user_email, "wrong_password")
      assert_error(conn)
    end

    test "returns authenticated:false if both email and password are invalid" do
      conn =
        AdminUserAuthenticator.authenticate(build_conn(), "wrong@example.com", "wrong_password")

      assert_error(conn)
    end

    test "returns authenticated:false if email is missing" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), nil, @password)
      assert_error(conn)
    end

    test "returns authenticated:false if password is missing" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), @user_email, nil)
      assert_error(conn)
    end

    test "returns authenticated:false both email and password are missing" do
      conn = AdminUserAuthenticator.authenticate(build_conn(), nil, nil)
      assert_error(conn)
    end

    test "returns authenticated:false if user is disabled" do
      admin = get_test_admin()
      User.enable_or_disable(admin, %{enabled: false, originator: %System{}})
      conn = AdminUserAuthenticator.authenticate(build_conn(), @user_email, @password)
      assert_error(conn)
    end
  end

  defp assert_success(conn) do
    assert conn.assigns.authenticated == true
    assert conn.assigns.admin_user.uuid == get_test_admin().uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :admin_user)
  end
end
