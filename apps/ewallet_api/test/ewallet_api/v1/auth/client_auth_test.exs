defmodule EWalletAPI.V1.ClientAuthTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWalletAPI.V1.ClientAuth
  alias EWalletDB.AuthToken

  def auth_header(key, token) do
    encoded_key = Base.encode64(key <> ":" <> token)

    ClientAuth.authenticate(%{
<<<<<<< HEAD
      headers: %{
=======
      "headers" => %{
>>>>>>> develop
        "authorization" => "OMGClient #{encoded_key}"
      }
    })
  end

  setup do
    user = insert(:user)

    %{
      user: user,
      api_key: insert(:api_key, owner_app: "ewallet_api"),
      auth_token: insert(:auth_token, user: user, owner_app: "ewallet_api")
    }
  end

  describe "authenticate/1" do
    test "assigns user if api key and auth token are correct", meta do
      auth = auth_header(meta.api_key.key, meta.auth_token.token)

      assert auth.authenticated
      assert auth[:authenticated] == true
      assert auth[:account] != nil
      assert auth[:user] != nil
    end

    test "halts with :invalid_api_key if api_key is missing", meta do
      auth = auth_header("", meta.auth_token.token)

      assert auth.authenticated == false
      assert auth[:auth_error] == :invalid_api_key
      assert auth[:account] == nil
      assert auth[:user] == nil
    end

    test "halts with :invalid_api_key if api_key is incorrect", meta do
      auth = auth_header("abc", meta.auth_token.token)

      assert auth.authenticated == false
      assert auth[:auth_error] == :invalid_api_key
      assert auth[:account] == nil
      assert auth[:user] == nil
    end

    test "halts with :auth_token_not_found if auth_token is missing", meta do
      auth = auth_header(meta.api_key.key, "")

      assert auth.authenticated == false
      assert auth[:auth_error] == :auth_token_not_found
      assert auth[:account].uuid == meta.api_key.account.uuid
      assert auth[:user] == nil
    end

    test "halts with :auth_token_not_found if auth_token is incorrect", meta do
      auth = auth_header(meta.api_key.key, "abc")

      assert auth.authenticated == false
      assert auth[:auth_error] == :auth_token_not_found
      assert auth[:account].uuid == meta.api_key.account.uuid
      assert auth[:user] == nil
    end

    test "halts with :auth_token_expired if auth_token exists but expired", meta do
      {:ok, auth_token} = AuthToken.expire(meta.auth_token.token, :ewallet_api)
      auth = auth_header(meta.api_key.key, auth_token.token)

      assert auth.authenticated == false
      assert auth[:auth_error] == :auth_token_expired
      assert auth[:account].uuid == meta.api_key.account.uuid
      assert auth[:user] == nil
    end

    test "halts with :invalid_auth_scheme if auth header is not provided" do
      auth =
        ClientAuth.authenticate(%{
          headers: %{}
        })

      assert auth.authenticated == false
      assert auth[:auth_error] == :invalid_auth_scheme
      assert auth[:account] == nil
      assert auth[:user] == nil
    end

    test "halts with :invalid_auth_scheme if auth header is not a valid auth scheme" do
      auth =
        ClientAuth.authenticate(%{
          headers: %{
            "authorization" => "InvalidScheme abc"
          }
        })

      assert auth.authenticated == false
      assert auth[:auth_error] == :invalid_auth_scheme
      assert auth[:account] == nil
      assert auth[:user] == nil
    end

    test "halts with :invalid_auth_scheme if auth header is invalid" do
      auth =
        ClientAuth.authenticate(%{
          headers: %{
            "authorization" => "OMGClient not_colon_separated_base64"
          }
        })

      assert auth.authenticated == false
      assert auth[:auth_error] == :invalid_auth_scheme
      assert auth[:account] == nil
      assert auth[:user] == nil
    end
  end
end
