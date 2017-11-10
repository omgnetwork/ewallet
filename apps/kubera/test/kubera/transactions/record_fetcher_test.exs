defmodule Kubera.Transactions.RecordFetcherTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias Kubera.Transactions.RecordFetcher
  alias KuberaDB.{Repo, MintedToken, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "fetch_user_and_minted_token/2" do
    test "fetch the user and minted token correctly" do
      symbol = "OMG"
      provider_user_id = "123456789"
      {:ok, inserted_token} =
        MintedToken.insert(params_for(:minted_token, %{symbol: symbol}))
      {:ok, inserted_user} =
        User.insert(params_for(:user, %{provider_user_id: provider_user_id}))

      {:ok, user, minted_token} =
        RecordFetcher.fetch_user_and_minted_token(provider_user_id, symbol)

      assert user == inserted_user
      assert minted_token == inserted_token
    end

    test "Should raise an error if the user is not found" do
      symbol = "OMG"
      MintedToken.insert(params_for(:minted_token, %{symbol: symbol}))
      provider_user_id = "invalid_provider_user_id"

      res = RecordFetcher.fetch_user_and_minted_token(provider_user_id, symbol)

      assert res == {:error, :provider_user_id_not_found}
    end

    test "Should raise an error if the minted token is not found" do
      symbol = "invalid_symbol"
      provider_user_id = "123456789"
      User.insert(params_for(:user, %{provider_user_id: provider_user_id}))

      res = RecordFetcher.fetch_user_and_minted_token(provider_user_id, symbol)

      assert res == {:error, :minted_token_not_found}
    end
  end
end
