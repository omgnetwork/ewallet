defmodule EWallet.Web.PreloaderTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.Preloader
  alias EWalletDB.{Repo, Token, Transfer}

  defp prepare_test_transactions do
    insert(:transfer)
    insert(:transfer)
  end

  describe "EWallet.Web.Preloader.to_query/2" do
    test "preloads the token association" do
      prepare_test_transactions()

      result =
        Transfer
        |> Preloader.to_query([:token])
        |> Repo.all()

      assert Enum.count(result) == 2
      assert %Token{} = Enum.at(result, 0).token
    end
  end
end
