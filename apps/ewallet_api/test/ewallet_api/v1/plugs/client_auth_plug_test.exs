defmodule EWalletAPI.V1.ClientAuthPlugTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.ClientAuthPlug
  alias EWalletDB.AuthToken

  describe "ClientAuthPlug.call/2" do
    test "assigns user if api key and auth token are correct" do
      conn = invoke_conn(@api_key, @auth_token)

      refute conn.halted
      assert conn.assigns[:authenticated] == true
      assert conn.assigns[:auth_scheme] == :client
      assert conn.assigns.end_user.username == @username
    end

    test "halts with :invalid_api_key if api_key is missing" do
      conn = invoke_conn("", @auth_token)
      assert_error(conn, "client:invalid_api_key")
    end

    test "halts with :invalid_api_key if api_key is incorrect" do
      conn = invoke_conn("wrong_api_key", @auth_token)
      assert_error(conn, "client:invalid_api_key")
    end

    test "halts with :auth_token_not_found if auth_token is missing" do
      conn = invoke_conn(@api_key, "")
      assert_error(conn, "user:auth_token_not_found")
    end

    test "halts with :auth_token_not_found if auth_token is incorrect" do
      conn = invoke_conn(@api_key, "wrong_auth_token")
      assert_error(conn, "user:auth_token_not_found")
    end

    test "halts with :auth_token_expired if auth_token exists but expired" do
      AuthToken.expire(@auth_token, :ewallet_api)
      conn = invoke_conn(@api_key, @auth_token)
      assert_error(conn, "user:auth_token_expired")
    end
  end

  describe "ClientAuthPlug.call/2 with invalid auth scheme" do
    test "halts with :invalid_auth_scheme if auth header is not provided" do
      conn = build_conn() |> ClientAuthPlug.call([])
      assert_error(conn, "client:invalid_auth_scheme")
    end

    test "halts with :invalid_auth_scheme if auth scheme is not supported" do
      conn = invoke_conn("InvalidScheme", @api_key, @auth_token)
      assert_error(conn, "client:invalid_auth_scheme")
    end

    test "halts with :invalid_auth_scheme if credentials format is invalid" do
      conn =
        build_conn()
        |> put_auth_header("OMGClient", "not_colon_separated_base64")
        |> ClientAuthPlug.call([])

      assert_error(conn, "client:invalid_auth_scheme")
    end
  end

  describe "ClientAuthPlug.expire_token/1" do
    test "expires auth token from the given connection successfully" do
      assert AuthToken.authenticate(@auth_token, :ewallet_api)

      conn =
        @api_key
        |> invoke_conn(@auth_token)
        |> ClientAuthPlug.expire_token()

      # Not using `ClientAuthTest.assert_error/2` because it does not follow
      # the typical unauthenticated flow. Expiring a token should be treated
      # as a successful authenticated call but with all auth info invalidated.
      refute conn.halted
      assert AuthToken.authenticate(@auth_token, :ewallet_api) == :token_expired
      refute conn.assigns[:authenticated]
      refute conn.assigns[:end_user]
    end
  end

  defp invoke_conn(api_key, auth_token), do: invoke_conn("OMGClient", api_key, auth_token)

  defp invoke_conn(type, api_key, auth_token) do
    build_conn()
    |> put_auth_header(type, api_key, auth_token)
    |> ClientAuthPlug.call([])
  end

  defp assert_error(conn, error_code) do
    # Assert connection behaviors
    assert conn.halted
    assert conn.status == 200
    refute conn.assigns[:authenticated]
    refute Map.has_key?(conn.assigns, :user)

    # Assert response body data
    body = json_response(conn, :ok)
    assert body["data"]["code"] == error_code
  end
end
