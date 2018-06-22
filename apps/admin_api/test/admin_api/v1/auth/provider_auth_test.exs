defmodule AdminAPI.Web.V1.ProviderAuthTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.V1.ProviderAuth

  def auth_header(access_key, secret_key) do
    encoded_key = Base.encode64(access_key <> ":" <> secret_key)
    ProviderAuth.authenticate(%{auth_header: "OMGProvider #{encoded_key}"})
  end

  setup do
    %{key: insert(:key)}
  end

  describe "authenticate/1" do
    test "returns authenticated: true when given valid access_key/token", meta do
      auth = auth_header(meta.key.access_key, meta.key.secret_key)

      assert auth.authenticated == true
      assert auth.key.uuid == meta.key.uuid
      assert auth.auth_access_key == meta.key.access_key
      assert auth.auth_secret_key == meta.key.secret_key
    end

    test "returns authenticated: false when given invalid access_key", meta do
      auth = auth_header("fake_access_key", meta.key.secret_key)

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_access_secret_key

      assert auth[:key] == nil
      assert auth[:auth_access_key] == "fake_access_key"
      assert auth[:auth_secret_key] == meta.key.secret_key
    end

    test "returns authenticated: false when given invalid token", meta do
      auth = auth_header(meta.key.access_key, "fake_secret_key")

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_access_secret_key

      assert auth[:key] == nil
      assert auth[:auth_access_key] == meta.key.access_key
      assert auth[:auth_secret_key] == "fake_secret_key"
    end

    test "returns authenticated: false when given invalid auth scheme", meta do
      encoded_key = Base.encode64(meta.key.access_key <> ":" <> meta.key.secret_key)
      auth = ProviderAuth.authenticate(%{auth_header: "FAKEAdmin #{encoded_key}"})

      assert auth.authenticated == false
      assert auth.auth_error == :invalid_auth_scheme

      assert auth[:key] == nil
      assert auth[:auth_access_key] == nil
      assert auth[:auth_secret_key] == nil
    end
  end
end
