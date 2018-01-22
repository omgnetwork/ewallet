defmodule EWallet.Web.PreloaderTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias EWallet.Web.Preloader
  alias EWalletDB.{Repo, MintedToken, Transfer}

  defp prepare_test_transactions do
    insert(:transfer)
    insert(:transfer)
  end

  describe "EWallet.Web.Preloader.to_query/2" do
    test "preloads the minted token association" do
      prepare_test_transactions()

      result =
        Transfer
        |> Preloader.to_query([:minted_token])
        |> Repo.all()

      assert Enum.count(result) == 2
      assert %MintedToken{} = Enum.at(result, 0).minted_token
    end
  end
end
