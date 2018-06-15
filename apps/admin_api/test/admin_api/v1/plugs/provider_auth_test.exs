defmodule AdminAPI.V1.Plug.ProviderAuthTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.ProviderAuth

  describe "V1.Plugs.ProviderAuth with OMGProvider auth type" do
    test "assigns authenticated and account if access/secret key are correct" do
      conn = invoke_conn(@access_key, @secret_key)

      refute conn.halted
      assert conn.assigns[:authenticated]
      assert Map.has_key?(conn.assigns, :account)
    end

    test "halts with :invalid_access_secret_key if access key is missing" do
      conn = invoke_conn("", @secret_key)
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if access key is incorrect" do
      conn = invoke_conn("wrong_access_key", @secret_key)
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if secret key is missing" do
      conn = invoke_conn(@access_key, "")
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if secret key is incorrect" do
      conn = invoke_conn(@access_key, "invalid_secret")
      assert_error(conn, "client:invalid_access_secret_key")
    end
  end

  describe "V1.Plugs.ProviderAuth with Basic auth type" do
    test "assigns authenticated and account if access/secret key are correct" do
      conn = invoke_conn("Basic", @access_key, @secret_key)

      refute conn.halted
      assert conn.assigns[:authenticated]
      assert Map.has_key?(conn.assigns, :account)
    end

    test "halts with :invalid_access_secret_key if access key is missing" do
      conn = invoke_conn("Basic", "", @secret_key)
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if access key is incorrect" do
      conn = invoke_conn("Basic", "wrong_access_key", @secret_key)
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if secret key is missing" do
      conn = invoke_conn("Basic", @access_key, "")
      assert_error(conn, "client:invalid_access_secret_key")
    end

    test "halts with :invalid_access_secret_key if secret key is incorrect" do
      conn = invoke_conn("Basic", @access_key, "invalid_secret")
      assert_error(conn, "client:invalid_access_secret_key")
    end
  end

  describe "V1.Plugs.ProviderAuth with invalid auth scheme" do
    test "halts with :invalid_auth_scheme if auth header is not provided" do
      conn = build_conn() |> ProviderAuth.call([])
      assert_error(conn, "client:invalid_auth_scheme")
    end

    test "halts with :invalid_auth_scheme if auth scheme is not supported" do
      conn = invoke_conn("InvalidScheme", @access_key, @secret_key)
      assert_error(conn, "client:invalid_auth_scheme")
    end

    test "halts with :invalid_auth_scheme if credentials format is invalid" do
      conn =
        build_conn()
        |> put_auth_header("OMGProvider", "not_colon_separated_base64")
        |> ProviderAuth.call([])

      assert_error(conn, "client:invalid_auth_scheme")
    end
  end

  defp invoke_conn(api_key, auth_token), do: invoke_conn("OMGProvider", api_key, auth_token)

  defp invoke_conn(type, api_key, auth_token) do
    build_conn()
    |> put_auth_header(type, api_key, auth_token)
    |> ProviderAuth.call([])
  end

  defp assert_error(conn, error_code) do
    # Assert connection behaviors
    assert conn.halted
    assert conn.status == 200
    refute conn.assigns[:authenticated]
    refute Map.has_key?(conn.assigns, :account)

    # Assert response body data
    body = json_response(conn, :ok)
    assert body["data"]["code"] == error_code
  end
end
