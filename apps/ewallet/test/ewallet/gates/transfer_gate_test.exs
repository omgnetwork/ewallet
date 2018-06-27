defmodule EWallet.TransferGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.TransferGate
  alias EWalletDB.{Repo, Token, Account, Transaction}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)
    {:ok, account1} = Account.insert(params_for(:account))
    {:ok, account2} = Account.insert(params_for(:account))
    {:ok, token} = Token.insert(params_for(:token, subunit_to_unit: 100))
    from = Account.get_primary_wallet(account1)
    to = Account.get_primary_wallet(account2)

    mint!(token)
    transfer!(master_wallet.address, from.address, token, 1_000 * token.subunit_to_unit)

    %{
      idempotency_token: UUID.generate(),
      from: from.address,
      to: to.address,
      from_amount: 100 * token.subunit_to_unit,
      from_token_id: token.id,
      to_amount: 100 * token.subunit_to_unit,
      to_token_id: token.id,
      exchange_account_id: nil,
      metadata: %{},
      payload: %{}
    }
  end

  describe "get_or_insert/1" do
    test "inserts a new internal transfer when not existing", attrs do
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:ok, inserted_transaction} = TransferGate.get_or_insert(attrs)

      transaction = Transaction.get_by_idempotency_token(attrs.idempotency_token)
      assert transaction.id == inserted_transaction.id
      assert transaction.type == Transaction.internal()
    end

    test "gets a transfer if already existing", attrs do
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil
      assert Transaction |> Repo.all() |> length() == 2

      {:ok, inserted_transaction1} = TransferGate.get_or_insert(attrs)
      {:ok, inserted_transaction2} = TransferGate.get_or_insert(attrs)

      assert inserted_transaction1.id == inserted_transaction2.id
      assert Transaction |> Repo.all() |> length() == 3
    end

    test "fails to insert a transfer from a burn wallet", attrs do
      master_account = Account.get_master_account()
      burn_wallet = Account.get_default_burn_wallet(master_account)

      attrs = attrs |> Map.put(:from, burn_wallet.address)
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:error, changeset} = TransferGate.get_or_insert(attrs)

      assert changeset.errors == [
               from:
                 {"can't be the address of a burn wallet",
                  [validation: :burn_wallet_as_sender_not_allowed]}
             ]
    end

    test "fails to insert a transfer from an additional burn wallet", attrs do
      master_account = Account.get_master_account()
      burn_wallet = insert(:wallet, account: master_account, identifier: "burn_1")

      attrs = attrs |> Map.put(:from, burn_wallet.address)
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:error, changeset} = TransferGate.get_or_insert(attrs)

      assert changeset.errors == [
               from:
                 {"can't be the address of a burn wallet",
                  [validation: :burn_wallet_as_sender_not_allowed]}
             ]
    end
  end

  describe "process/1 for same token transactions" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.process(transfer)

      assert transfer.local_ledger_uuid != nil
      assert transfer.status == Transaction.confirmed()
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      attrs =
        attrs
        |> Map.put(:from_amount, 1_000_000)
        |> Map.put(:to_amount, 1_000_000)

      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.process(transfer)

      assert transfer.status == Transaction.failed()
      assert transfer.error_code == "insufficient_funds"
      assert transfer.error_description == nil

      assert transfer.error_data == %{
               "address" => attrs[:from],
               "amount_to_debit" => 1_000_000,
               "current_amount" => 100_000,
               "token_id" => attrs[:from_token_id]
             }

      assert transfer.status == Transaction.failed()
    end

    test "returns the previously inserted transfer", attrs do
      assert Transaction |> Repo.all() |> length() == 2

      {:ok, transfer_1} = TransferGate.get_or_insert(attrs)
      transfer_1 = TransferGate.process(transfer_1)

      assert transfer_1.local_ledger_uuid != nil
      assert transfer_1.status == Transaction.confirmed()

      transfer_2 = TransferGate.process(transfer_1)

      assert transfer_2.local_ledger_uuid != nil
      assert transfer_2.status == Transaction.confirmed()
      assert transfer_1.uuid == transfer_2.uuid
      assert Transaction |> Repo.all() |> length() == 3
    end
  end

  describe "process/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      account = Account.get_master_account()
      to_token = insert(:token)
      mint!(to_token)

      {:ok, transfer} =
        attrs
        |> Map.merge(%{to_token_id: to_token.id, exchange_account_id: account.id})
        |> TransferGate.get_or_insert()

      transfer = TransferGate.process(transfer)

      assert transfer.local_ledger_uuid != nil
      assert transfer.status == Transaction.confirmed()
    end
  end

  describe "genesis/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.genesis(transfer)

      assert transfer.status == Transaction.confirmed()
      assert transfer.local_ledger_uuid != nil
    end
  end
end
