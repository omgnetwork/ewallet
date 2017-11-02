defmodule Kubera.TransactionTest do
  use ExUnit.Case
  import KuberaDB.Factory
  import Mock
  alias Kubera.Transaction
  alias KuberaDB.{Repo, User, MintedToken}
  alias KuberaMQ.Entry
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "init/1" do
    test "builds the set of attributes needed for creation" do
      {:ok, user} = User.insert(params_for(:user))
      {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

      res = Transaction.init(%{
        "provider_user_id" => user.provider_user_id,
        "symbol" => minted_token.symbol,
        "amount" => 100_000,
        "metadata" => %{}
      })

      assert res == %{
        from: MintedToken.get_main_balance(minted_token),
        to: User.get_main_balance(user),
        minted_token: minted_token,
        amount: 100_000,
        metadata: %{}
      }
    end
  end

  describe "create/2" do
    test "sends the transaction to the local ledger" do
      with_mock Entry,
        [insert: fn _data, callback ->
          callback.({:ok, %{data: "from ledger"}})
        end] do
          {:ok, user} = User.insert(params_for(:user))
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          Transaction.create(%{
            from: MintedToken.get_main_balance(minted_token),
            to: User.get_main_balance(user),
            minted_token: minted_token,
            amount: 100_000,
            metadata: %{}
          }, fn {res, data} ->
            assert res == :ok
            assert data == %{data: "from ledger"}
          end)
      end
    end
  end
end
