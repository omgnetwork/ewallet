defmodule AdminAPI.V1.AdminAPIAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminAPIAuthPlug
  alias Ecto.UUID

  describe "AdminAPIAuthPlug.call/2 with provider auth" do
    test "authenticates if both access key and secret key are correct" do
      conn = test_with("OMGProvider", @access_key, @secret_key)

      refute conn.halted
      assert conn.assigns.authenticated == :provider
      assert conn.assigns[:user] == nil
      assert conn.private[:auth_access_key] == @access_key
    end

    test "halts the conn when authorization header is not provided" do
      conn = AdminAPIAuthPlug.call(build_conn(), nil)

      assert conn.halted
      assert conn.assigns.authenticated == false
    end
  end

  describe "AdminAPIAuthPlug.call/2 with enable_client_auth == true" do
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

  describe "AdminAPIAuthPlug.call/2 with enable_client_auth is false" do
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

  defp test_with(type, api_key_id, api_key, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [api_key_id, api_key, user_id, auth_token])
    |> AdminAPIAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp test_with(type, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [user_id, auth_token])
    |> AdminAPIAuthPlug.call(enable_client_auth: client_auth?)
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
