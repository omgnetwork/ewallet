defmodule AdminAPI.V1.AdminAPIAuthPlugTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.AdminAPIAuthPlug

  describe "AdminAPIAuthPlug.call/2 with provider auth" do
    test "authenticates if both access key and secret key are correct" do
      conn = test_with("OMGProvider", @access_key, @secret_key)

      refute conn.halted
      assert conn.assigns.authenticated == true
      assert conn.assigns.auth_scheme == :provider
      assert conn.assigns[:admin_user] == nil
      assert conn.private[:auth_access_key] == @access_key
    end

    test "fails to authenticate if an invalid access key is provided" do
      conn = test_with("OMGProvider", "fake", @secret_key)

      assert conn.halted
      assert conn.assigns.authenticated == false
    end

    test "fails to authenticate if an invalid secret key is provided" do
      conn = test_with("OMGProvider", @access_key, "fake")

      assert conn.halted
      assert conn.assigns.authenticated == false
    end

    test "halts the conn when authorization header is not provided" do
      conn = AdminAPIAuthPlug.call(build_conn(), nil)

      assert conn.halted
      assert conn.assigns.authenticated == false
    end
  end

  describe "AdminAPIAuthPlug.call/2 with enable_client_auth is false" do
    test "authenticates if user credentials are correct " do
      conn = test_with("OMGAdmin", @admin_id, @auth_token, false)

      refute conn.halted
      assert_success(conn)
    end

    test "halts if user credentials are incorrect (token)" do
      conn = test_with("OMGAdmin", @admin_id, "bad_token", false)

      assert conn.halted
      assert_error(conn)
    end

    test "halts if user credentials are incorrect (admin user id)" do
      conn = test_with("OMGAdmin", "fake", @auth_token, false)

      assert conn.halted
      assert_error(conn)
    end
  end

  defp test_with(type, user_id, auth_token, client_auth? \\ true) do
    build_conn()
    |> put_auth_header(type, [user_id, auth_token])
    |> AdminAPIAuthPlug.call(enable_client_auth: client_auth?)
  end

  defp assert_success(conn) do
    assert conn.assigns.authenticated == true
    assert conn.assigns.auth_scheme == :admin
    assert conn.assigns.admin_user.uuid == get_test_admin().uuid
  end

  defp assert_error(conn) do
    refute conn.assigns.authenticated
    refute Map.has_key?(conn.assigns, :admin_user)
  end
end
