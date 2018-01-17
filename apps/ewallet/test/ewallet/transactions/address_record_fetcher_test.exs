defmodule EWallet.Transactions.AddressRecordFetcherTest do
  use ExUnit.Case
  import EWalletDB.Factory
  alias EWallet.Transactions.AddressRecordFetcher
  alias EWalletDB.{Repo, MintedToken, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "fetch/2" do
    test "fetches the from, to and minted token correctly" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user1} = User.insert(params_for(:user))
      {:ok, inserted_user2} = User.insert(params_for(:user))

      from = User.get_primary_balance(inserted_user1)
      to = User.get_primary_balance(inserted_user2)

      {:ok, from_balance, to_balance, minted_token} =
        AddressRecordFetcher.fetch(%{
          "from_address" => from.address,
          "to_address" => to.address,
          "token_id" => inserted_token.friendly_id
        })

      assert from_balance == from
      assert to_balance == to
      assert minted_token == inserted_token
    end

    test "raises an error if the from address is not found" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => "123",
          "to_address" => User.get_primary_balance(inserted_user).address,
          "token_id" => inserted_token.friendly_id
        })

      assert res == {:error, :from_address_not_found}
    end

    test "raises an error if the to address is not found" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => User.get_primary_balance(inserted_user).address,
          "to_address" => "123",
          "token_id" => inserted_token.friendly_id
        })

      assert res == {:error, :to_address_not_found}
    end

    test "raises an error if the to minted token is not found" do
      {:ok, inserted_user1} = User.insert(params_for(:user))
      {:ok, inserted_user2} = User.insert(params_for(:user))

      to = User.get_primary_balance(inserted_user1).address
      from = User.get_primary_balance(inserted_user2).address

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => from,
          "to_address" => to,
          "token_id" => "123"
        })

      assert res == {:error, :minted_token_not_found}
    end
  end
end
