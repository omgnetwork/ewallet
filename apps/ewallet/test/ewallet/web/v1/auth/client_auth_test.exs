defmodule EWallet.Web.V1.ClientAuthTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Web.V1.ClientAuth
  alias EWalletDB.Repo

  describe "parse_header/1" do
    test "extracts the key and token" do
      encoded = Base.encode64("abc:def")
      res = ClientAuth.parse_header("OMGClient #{encoded}")

      assert res == {:ok, "abc", "def"}
    end
  end

  describe "authenticate_client/2" do
    test "returns :ok if api key and auth token are correct" do
      api_key = :api_key |> insert(owner_app: "ewallet_api") |> Repo.preload(:account)
      {res, account} = ClientAuth.authenticate_client(api_key.key, :ewallet_api)

      assert res == :ok
      assert api_key.account.uuid == account.uuid
    end
  end

  describe "authenticate_token/2" do
    test "returns :ok if api key and auth token are correct" do
      user = insert(:user)
      auth_token = insert(:auth_token, user: user, owner_app: "ewallet_api")
      res = ClientAuth.authenticate_token(auth_token.token, :ewallet_api)

      assert res == {:ok, auth_token.user}
    end
  end

  describe "expire_token/2" do
    test "returns :ok if api key and auth token are correct" do
      user = insert(:user)
      auth_token = insert(:auth_token, user: user, owner_app: "ewallet_api")
      assert auth_token.expired == false
      {:ok, auth_token} = ClientAuth.expire_token(auth_token.token, :ewallet_api)
      assert auth_token.expired == true
    end
  end
end
