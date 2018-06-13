defmodule EWallet.Web.V1.SocketProviderAuthTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.SocketProviderAuth

  def auth_header(access, secret) do
    encoded_key = Base.encode64(access <> ":" <> secret)

    SocketProviderAuth.authenticate(%{
      http_headers: %{
        "authorization" => "OMGProvider #{encoded_key}"
      }
    })
  end

  describe "authenticate/1" do
    test "sets authenticated and account if access/secret key are correct" do
      key = insert(:key)
      auth = auth_header(key.access_key, key.secret_key)

      assert auth.authenticated
      assert auth[:authenticated] == :provider
      assert auth[:account] != nil
      assert auth[:auth_access_key] == key.access_key
      assert auth[:auth_secret_key] == key.secret_key
    end

    test "halts with :invalid_access_secret_key if access key is missing" do
      key = insert(:key)
      auth = auth_header("", key.secret_key)

      refute auth.authenticated
      assert auth[:account] == nil
    end

    test "halts with :invalid_access_secret_key if access key is incorrect" do
      key = insert(:key)
      auth = auth_header("abc", key.secret_key)

      refute auth.authenticated
      assert auth[:account] == nil
    end

    test "halts with :invalid_access_secret_key if secret key is missing" do
      key = insert(:key)
      auth = auth_header(key.access_key, "")

      refute auth.authenticated
      assert auth[:account] == nil
    end

    test "halts with :invalid_access_secret_key if secret key is incorrect" do
      key = insert(:key)
      auth = auth_header(key.access_key, "abc")

      refute auth.authenticated
      assert auth[:account] == nil
    end

    test "halts with :invalid_auth_scheme if auth header is not provided" do
      auth =
        SocketProviderAuth.authenticate(%{
          http_headers: %{
            "authorization" => "FAKE test"
          }
        })

      refute auth.authenticated
      assert auth[:auth_error] == :invalid_auth_scheme
      assert auth[:account] == nil
    end
  end
end
