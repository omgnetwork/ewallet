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

  describe "process/2" do
    test "build, format and send the transaction to the local ledger" do
      with_mock Entry,
        [insert: fn _data ->
          {:ok, %{data: "from ledger"}}
        end] do
          {:ok, inserted_user} = User.insert(params_for(:user))
          {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))

          attrs = %{
            "provider_user_id" => inserted_user.provider_user_id,
            "symbol" => inserted_token.symbol,
            "amount" => 100_000,
            "metadata" => %{}
          }
          {status, user, minted_token} =
            Transaction.process(attrs, Transaction.debit_type)
          assert status == :ok
          assert user == inserted_user
          assert minted_token == inserted_token
      end
    end
  end
end
