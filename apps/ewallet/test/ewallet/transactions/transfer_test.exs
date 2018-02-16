 defmodule EWallet.Transactions.TransferTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.Transactions
  alias EWalletDB.{Repo, MintedToken, Account, Transfer}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    master_account  = Account.get_master_account()
    master_balance  = Account.get_primary_balance(master_account)
    {:ok, account1} = Account.insert(params_for(:account))
    {:ok, account2} = Account.insert(params_for(:account))
    {:ok, token}    = MintedToken.insert(params_for(:minted_token, subunit_to_unit: 100))
    from            = Account.get_primary_balance(account1)
    to              = Account.get_primary_balance(account2)

    mint!(token)
    transfer!(master_balance.address, from.address, token, 1_000 * token.subunit_to_unit)

    %{
      idempotency_token: UUID.generate(),
      from: from.address,
      to: to.address,
      minted_token_id: token.id,
      minted_token_friendly_id: token.friendly_id,
      amount: 100  * token.subunit_to_unit,
      metadata: %{},
      payload: %{}
    }
  end

  describe "get_or_insert/1" do
    test "inserts a new internal transfer when not existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

      {:ok, inserted_transfer} = Transactions.Transfer.get_or_insert(attrs)

      transfer = Transfer.get_by_idempotency_token(attrs.idempotency_token)
      assert transfer.id == inserted_transfer.id
      assert transfer.type == Transfer.internal
    end

    test "gets a transfer if already existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil
      assert Transfer |> Repo.all() |> length() == 2

      {:ok, inserted_transfer1} = Transactions.Transfer.get_or_insert(attrs)
      {:ok, inserted_transfer2} = Transactions.Transfer.get_or_insert(attrs)

      assert inserted_transfer1.id == inserted_transfer2.id
      assert Transfer |> Repo.all() |> length() == 3
    end
  end

  describe "process/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
      transfer = Transactions.Transfer.process(transfer)

      assert %{"entry_id" => _} = transfer.ledger_response
      assert transfer.status == Transfer.confirmed
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      attrs = Map.put(attrs, :amount, 1_000_000)
      {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
      transfer = Transactions.Transfer.process(transfer)

      assert res == :error
      assert code == "transaction:insufficient_funds"
      assert description == "The specified balance (#{attrs[:from]})" <>
                            " does not contain enough funds. Available: 100000 #{attrs[:minted_token_friendly_id]} - Attempted debit: 1000000 #{attrs[:minted_token_friendly_id]}"
      assert transfer.status == Transfer.failed
    end
  end

  describe "genesis/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
      transfer = Transactions.Transfer.genesis(transfer)

      assert transfer.status == Transfer.confirmed
      assert %{"entry_id" => _} = transfer.ledger_response
    end
  end
end
