defmodule Kubera.BalanceTest do
  use ExUnit.Case
  import KuberaDB.Factory
  import Mock
  alias Kubera.Balance
  alias KuberaDB.{Repo, User, MintedToken}
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
        {KuberaMQ.Balance, [], [all: fn _pid -> balances_response() end]}
        ] do
          {:ok, inserted_user} = User.insert(params_for(:user))
          {:ok, btc} =
            :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
          {:ok, omg} =
            :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()
          {:ok, mnt} =
            :minted_token |> params_for(friendly_id: "MNT:123", symbol: "MNT") |> MintedToken.insert()
          {status, addresses} =
            Balance.all(%{"provider_user_id" => inserted_user.provider_user_id})
          assert status == :ok
          assert length(addresses) == 1
          main_address = List.first(addresses)
          assert main_address.address ==
            User.get_main_balance(inserted_user).address
          assert main_address.balances == [
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
      {KuberaMQ.Balance, [], [get: fn _symbol, _pid -> balance_response() end]}
      ] do
        {:ok, inserted_user} = User.insert(params_for(:user))
        {:ok, omg} =
          :minted_token |> params_for(friendly_id: "OMG:123", symbol: "OMG") |> MintedToken.insert()
        {:ok, _} =
          :minted_token |> params_for(friendly_id: "BTC:123", symbol: "BTC") |> MintedToken.insert()
        {:ok, _} =
          :minted_token |> params_for(friendly_id: "MNT:123", symbol: "MNT") |> MintedToken.insert()

        user_address = User.get_main_balance(inserted_user).address
        {status, addresses} = Balance.get(omg.friendly_id, user_address)
        assert status == :ok
        assert length(addresses) == 1
        main_address = List.first(addresses)
        assert main_address.address ==
          User.get_main_balance(inserted_user).address
        assert main_address.balances == [
          %{minted_token: omg, amount: 1000},
        ]
    end
  end

  end
end
