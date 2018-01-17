defmodule EWallet.BalanceTest do
  use ExUnit.Case
  import EWalletDB.Factory
  import Mock
  alias EWallet.Balance
  alias EWalletDB.{Repo, User, MintedToken}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  def balances_response do
    {:ok, %{
      "object" => "balance",
      "address" => "master",
      "amounts" => %{"BTC:123" => 9850, "OMG:123" => 1000}
    }}
  end

  def balance_response do
    {:ok, %{
      "object" => "balance",
      "address" => "master",
      "amounts" => %{"OMG:123" => 1000}
    }}
  end

  describe "all/1" do
    test "retrieve all balances from a provider_user_id" do
      with_mocks [
        {EWalletMQ.Publishers.Balance, [], [all: fn _pid -> balances_response() end]}
        ] do
          {:ok, inserted_user} = User.insert(params_for(:user))
          {:ok, btc} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
          {:ok, omg} =
            :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()
          {:ok, mnt} =
            :minted_token |> params_for(friendly_id: "MNT:123", symbol: "MNT") |> MintedToken.insert()
          {status, address} =
            Balance.all(%{"provider_user_id" => inserted_user.provider_user_id})
          assert status == :ok
          assert address.address ==
            User.get_primary_balance(inserted_user).address
          assert address.balances == [
            %{minted_token: btc, amount: 9850},
            %{minted_token: omg, amount: 1000},
            %{minted_token: mnt, amount: 0}
          ]
      end
    end
  end

  describe "get/2" do
    test "retrieve the specific balance from a minted_token and an address" do
      with_mocks [
        {EWalletMQ.Publishers.Balance, [], [get: fn _symbol, _pid -> balance_response() end]}
      ] do
          {:ok, inserted_user} = User.insert(params_for(:user))
          {:ok, omg} =
            :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()
          {:ok, _} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
          {:ok, _} =
            :minted_token |> params_for(friendly_id: "MNT:123", symbol: "MNT") |> MintedToken.insert()

          user_address = User.get_primary_balance(inserted_user).address
          {status, address} = Balance.get(omg.friendly_id, user_address)
          assert status == :ok
          assert address.address ==
            User.get_primary_balance(inserted_user).address
          assert address.balances == [
            %{minted_token: omg, amount: 1000},
          ]
      end
    end
  end
end
