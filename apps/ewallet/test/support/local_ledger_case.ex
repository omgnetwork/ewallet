defmodule EWallet.LocalLedgerCase do
  @moduledoc """
  A test case template for tests that need to connect to the local ledger.
  """
  use ExUnit.CaseTemplate
  alias Ecto.UUID
  alias EWallet.{Mint, Transaction}
  alias EWalletDB.Account

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWalletDB.Factory
      import EWallet.LocalLedgerCase
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Account

      setup do
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(LocalLedgerDB.Repo)

        {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()

        :ok
      end
    end
  end

  def mint!(minted_token, amount \\ 1_000_000) do
    {:ok, mint, _transfer} = Mint.insert(%{
      "idempotency_token" => UUID.generate(),
      "token_id" => minted_token.friendly_id,
      "amount" => amount * minted_token.subunit_to_unit,
      "description" => "Minting #{amount} #{minted_token.symbol}",
      "metadata" => %{}
    })

    assert mint.confirmed == true
    mint
  end

  def transfer!(from, to, minted_token, amount) do
    {:ok, transfer, _balances, _minted_token} = Transaction.process_with_addresses(%{
      "from_address" => from,
      "to_address" => to,
      "token_id" => minted_token.friendly_id,
      "amount" => amount,
      "metadata" => %{},
      "idempotency_token" => UUID.generate()
    })

    transfer
  end

  def initialize_balance(balance, amount, minted_token) do
    master_account = Account.get_master_account()
    master_balance = Account.get_primary_balance(master_account)

    {:ok, transfer, _balances, _minted_token} = Transaction.process_with_addresses(%{
      "from_address" => master_balance.address,
      "to_address" => balance.address,
      "token_id" => minted_token.friendly_id,
      "amount" => amount * minted_token.subunit_to_unit,
      "metadata" => %{},
      "idempotency_token" => UUID.generate()
    })

    transfer
  end
end
