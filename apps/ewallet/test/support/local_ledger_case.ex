defmodule EWallet.LocalLedgerCase do
  @moduledoc """
  A test case template for tests that need to connect to the local ledger.
  """
  use ExUnit.CaseTemplate
  alias Ecto.UUID
  alias EWallet.{MintGate, TransactionGate}
  alias EWalletDB.Account
  alias EWalletConfig.ConfigTestHelper
  alias ActivityLogger.System

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWalletDB.Factory
      import EWallet.LocalLedgerCase
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Account

      setup tags do
        :ok = Sandbox.checkout(EWalletConfig.Repo)
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(LocalLedgerDB.Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)

        unless tags[:async] do
          Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
          Sandbox.mode(EWalletDB.Repo, {:shared, self()})
          Sandbox.mode(LocalLedgerDB.Repo, {:shared, self()})
          Sandbox.mode(ActivityLogger.Repo, {:shared, self()})
        end

        config_pid = start_supervised!(EWalletConfig.Config)

        ConfigTestHelper.restart_config_genserver(
          self(),
          config_pid,
          EWalletConfig.Repo,
          [:ewallet_db, :ewallet],
          %{
            "enable_standalone" => false,
            "base_url" => "http://localhost:4000",
            "email_adapter" => "test"
          }
        )

        {:ok, account} = :account |> params_for(parent: nil) |> Account.insert()

        :ok
      end
    end
  end

  def mint!(token, amount \\ 1_000_000) do
    {:ok, mint, _transaction} =
      MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "description" => "Minting #{amount} #{token.symbol}",
        "metadata" => %{},
        "originator" => %System{}
      })

    assert mint.confirmed == true
    mint
  end

  def transfer!(from, to, token, amount) do
    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => from,
        "to_address" => to,
        "token_id" => token.id,
        "amount" => amount,
        "metadata" => %{},
        "idempotency_token" => UUID.generate(),
        "originator" => %System{}
      })

    transaction
  end

  def initialize_wallet(wallet, amount, token) do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)

    {:ok, transaction} =
      TransactionGate.create(%{
        "from_address" => master_wallet.address,
        "to_address" => wallet.address,
        "token_id" => token.id,
        "amount" => amount * token.subunit_to_unit,
        "metadata" => %{},
        "idempotency_token" => UUID.generate(),
        "originator" => %System{}
      })

    transaction
  end
end
