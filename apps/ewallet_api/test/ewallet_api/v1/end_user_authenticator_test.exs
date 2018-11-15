defmodule EWalletAPI.Web.V1.EndUserAuthenticatorTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.EndUserAuthenticator
  alias EWalletConfig.Helpers.Crypto
  alias EWalletDB.User

  setup do
    email = "end_user_auth@example.com"
    password = "some_password"

    user =
      insert(:user, %{email: email, password_hash: Crypto.hash_password(password), enabled: true})

    %{
      email: email,
      password: password,
      user: user
    }
  end

  describe "authenticate/3" do
    test "returns conn with the user and authenticated:true if email and password are valid",
         context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, context.password)
      assert_success(conn, context)
    end

    test "returns conn with authenticated:false if email is invalid", context do
      conn =
        EndUserAuthenticator.authenticate(build_conn(), "wrong@example.com", context.password)

      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is invalid", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if both email and password are invalid",
         _context do
      conn =
        EndUserAuthenticator.authenticate(build_conn(), "wrong@example.com", "wrong_password")

      assert_error(conn)
    end

    test "returns conn with authenticated:false if email is missing", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), nil, context.password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is missing", context do
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false both email and password are missing", _context do
      conn = EndUserAuthenticator.authenticate(build_conn(), nil, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if user is disabled", context do
      User.enable_or_disable(context.user, %{enabled: false})
      conn = EndUserAuthenticator.authenticate(build_conn(), context.email, context.password)
      assert_error(conn)
    end
  end

  defp assert_success(conn, context) do
    assert conn.assigns.authenticated == true
    assert conn.assigns.end_user.uuid == context.user.uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :end_user)
  end
end
