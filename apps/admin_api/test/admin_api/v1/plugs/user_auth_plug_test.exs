defmodule AdminAPI.V1.UserAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.UserAuthPlug
  alias Ecto.UUID

  describe "UserAuthPlug.call/2 with enable_client_auth == true" do
    test "authenticates if both client and user credentials are correct" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @admin_id, @auth_token)

      refute conn.halted
      assert_success(conn)
    end

    test "halts if client credentials are incorrect" do
      conn = test_with("OMGAdmin", @api_key_id, "bad_api_key", @admin_id, @auth_token)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if user credentials are incorrect" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @admin_id, "bad_token")

      assert conn.halted
      assert_error(conn)
    end

    test "halfs if the auth token doesn't belong to the user_id" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, UUID.generate(), @auth_token)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if client credentials are not provided" do
      conn = test_with("OMGAdmin", @admin_id, @auth_token)

      assert conn.halted
      assert_error(conn)
    end
  end

  describe "UserAuthPlug.call/2 with enable_client_auth is false" do
    test "authenticates if user credentials are correct " do
      conn = test_with("OMGAdmin", @admin_id, @auth_token, false)

      refute conn.halted
      assert_success(conn)
    end

    test "halts if both client and user credentials are correct" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @admin_id, @auth_token, false)

      refute conn.halted
      assert_success(conn)
    end

    test "halts if user credentials are incorrect" do
      conn = test_with("OMGAdmin", @admin_id, "bad_token", false)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if both credentials are provided but client credentials are incorrect" do
      conn = test_with("OMGAdmin", @api_key_id, "bad_api_key", @admin_id, @auth_token, false)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if both credentials are provided but user credentials are incorrect" do
      conn = test_with("OMGAdmin", @api_key_id, @api_key, @admin_id, "bad_auth_token", false)

      assert conn.halted
      assert_error(conn)
    end
  end

  describe "UserAuthPlug.authenticate/3" do
    test "returns conn with the user and authenticated:true if email and password are valid" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, @password)
      assert_success(conn)
    end

    test "returns conn with authenticated:false if email is invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), "wrong@example.com", @password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if both email and password are invalid" do
      conn = UserAuthPlug.authenticate(build_conn(), "wrong@example.com", "wrong_password")
      assert_error(conn)
    end

    test "returns conn with authenticated:false if email is missing" do
      conn = UserAuthPlug.authenticate(build_conn(), nil, @password)
      assert_error(conn)
    end

    test "returns conn with authenticated:false if password is missing" do
      conn = UserAuthPlug.authenticate(build_conn(), @user_email, nil)
      assert_error(conn)
    end

    test "returns conn with authenticated:false both email and password are missing" do
      conn = UserAuthPlug.authenticate(build_conn(), nil, nil)
      assert_error(conn)
    end
  end

  defp test_with(type, api_key_id, api_key, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [api_key_id, api_key, user_id, auth_token])
    |> UserAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp test_with(type, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [user_id, auth_token])
    |> UserAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp assert_success(conn) do
    assert conn.assigns.authenticated == :user
    assert conn.assigns.user.uuid == get_test_admin().uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :user)
  end
end
