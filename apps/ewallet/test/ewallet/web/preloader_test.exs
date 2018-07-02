defmodule EWallet.Web.PreloaderTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.Preloader
  alias EWalletDB.{Repo, Token, Transaction}

  defp prepare_test_transactions do
    insert(:transaction)
    insert(:transaction)
  end

  describe "EWallet.Web.Preloader.to_query/2" do
    test "preloads the from_token association" do
      prepare_test_transactions()

      result =
        Transaction
        |> Preloader.to_query([:from_token])
        |> Repo.all()

      assert Enum.count(result) == 2
      assert %Token{} = Enum.at(result, 0).from_token
    end
  end
end
