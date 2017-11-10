defmodule Kubera.Transactions.FormatterTest do
  use ExUnit.Case
  import KuberaDB.Factory
  alias Kubera.Transactions.Formatter
  alias KuberaDB.{Repo, MintedToken, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "format/5" do
    test "formats the transaction correctly" do
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {:ok, user} = User.insert(params_for(:user))
      master_balance = MintedToken.get_master_balance(inserted_token)
      user_balance = User.get_main_balance(user)

      transaction = Formatter.format(master_balance,
                                     user_balance,
                                     inserted_token,
                                     1,
                                     %{"test" => "test"})

      assert transaction == %{
        from: master_balance,
        to: user_balance,
        minted_token: inserted_token,
        amount: 1,
        metadata: %{"test" => "test"}
      }
    end
  end
end
