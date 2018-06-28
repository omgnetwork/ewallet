defmodule EWallet.AddressRecordFetcherTest do
  use ExUnit.Case
  import EWalletDB.Factory
  alias EWallet.AddressRecordFetcher
  alias EWalletDB.{Repo, Token, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "fetch/2" do
    test "fetches the from, to and token correctly" do
      {:ok, inserted_token} = Token.insert(params_for(:token))
      {:ok, inserted_user1} = User.insert(params_for(:user))
      {:ok, inserted_user2} = User.insert(params_for(:user))

      from = User.get_primary_wallet(inserted_user1)
      to = User.get_primary_wallet(inserted_user2)

      {:ok, from_wallet, to_wallet, token} =
        AddressRecordFetcher.fetch(%{
          "from_address" => from.address,
          "to_address" => to.address,
          "token_id" => inserted_token.id
        })

      assert from_wallet == from
      assert to_wallet == to
      assert token == inserted_token
    end

    test "raises an error if the from address is not found" do
      {:ok, inserted_token} = Token.insert(params_for(:token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => "none-0000-0000-0000",
          "to_address" => User.get_primary_wallet(inserted_user).address,
          "token_id" => inserted_token.id
        })

      assert res == {:error, :from_address_not_found}
    end

    test "raises an error if the to address is not found" do
      {:ok, inserted_token} = Token.insert(params_for(:token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => User.get_primary_wallet(inserted_user).address,
          "to_address" => "none-0000-0000-0000",
          "token_id" => inserted_token.id
        })

      assert res == {:error, :to_address_not_found}
    end

    test "raises an error if the to token is not found" do
      {:ok, inserted_user1} = User.insert(params_for(:user))
      {:ok, inserted_user2} = User.insert(params_for(:user))

      to = User.get_primary_wallet(inserted_user1).address
      from = User.get_primary_wallet(inserted_user2).address

      res =
        AddressRecordFetcher.fetch(%{
          "from_address" => from,
          "to_address" => to,
          "token_id" => "123"
        })

      assert res == {:error, :token_not_found}
    end
  end
end
