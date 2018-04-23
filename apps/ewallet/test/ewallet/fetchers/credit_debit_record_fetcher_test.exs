defmodule EWallet.CreditDebitRecordFetcherTest do
  use ExUnit.Case
  import EWalletDB.Factory
  alias EWallet.CreditDebitRecordFetcher
  alias EWalletDB.{Repo, MintedToken, User, Account}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "fetch/2" do
    test "fetches the user and minted token correctly" do
      {:ok, inserted_account} = Account.insert(params_for(:account))
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      {:ok, account, user, minted_token} =
        CreditDebitRecordFetcher.fetch(%{
          "provider_user_id" => inserted_user.provider_user_id,
          "token_id" => inserted_token.id
        })

      assert account.uuid != inserted_account.uuid
      assert account.uuid == inserted_token.account_uuid
      assert user == inserted_user
      assert minted_token == inserted_token
    end

    test "returns the given account if provided" do
      {:ok, inserted_account} = Account.insert(params_for(:account))
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      {:ok, account, user, minted_token} =
        CreditDebitRecordFetcher.fetch(%{
          "provider_user_id" => inserted_user.provider_user_id,
          "token_id" => inserted_token.id,
          "account_id" => inserted_account.id
        })

      assert account.uuid == inserted_account.uuid
      assert user == inserted_user
      assert minted_token == inserted_token
    end

    test "raises an error if the user is not found" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      provider_user_id = "invalid_provider_user_id"

      res = CreditDebitRecordFetcher.fetch(%{
        "provider_user_id" => provider_user_id,
        "token_id" => inserted_token.id
      })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "raises an error if the account is not found" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res = CreditDebitRecordFetcher.fetch(%{
        "provider_user_id" => inserted_user.provider_user_id,
        "token_id" =>  inserted_token.id,
        "account_id" => "acc_12345678901234567890123456"
      })

      assert res == {:error, :account_id_not_found}
    end

    test "raises an error if the minted token is not found" do
      {:ok, inserted_account} = Account.insert(params_for(:account))
      {:ok, inserted_user} = User.insert(params_for(:user))

      res = CreditDebitRecordFetcher.fetch(%{
        "provider_user_id" => inserted_user.provider_user_id,
        "token_id" =>  "invalid_id",
        "account_id" => inserted_account.id
      })

      assert res == {:error, :minted_token_not_found}
    end
  end
end
