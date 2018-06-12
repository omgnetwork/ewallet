defmodule EWallet.TransferTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.TransferGate
  alias EWalletDB.{Repo, Token, Account, Transfer}
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
      token_id: token.id,
      amount: 100 * token.subunit_to_unit,
      metadata: %{},
      payload: %{}
    }
  end

  describe "get_or_insert/1" do
    test "inserts a new internal transfer when not existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

      {:ok, inserted_transfer} = TransferGate.get_or_insert(attrs)

      transfer = Transfer.get_by_idempotency_token(attrs.idempotency_token)
      assert transfer.id == inserted_transfer.id
      assert transfer.type == Transfer.internal()
    end

    test "gets a transfer if already existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil
      assert Transfer |> Repo.all() |> length() == 2

      {:ok, inserted_transfer1} = TransferGate.get_or_insert(attrs)
      {:ok, inserted_transfer2} = TransferGate.get_or_insert(attrs)

      assert inserted_transfer1.id == inserted_transfer2.id
      assert Transfer |> Repo.all() |> length() == 3
    end

    test "fails to insert a transfer from a burn wallet", attrs do
      master_account = Account.get_master_account()
      burn_wallet = Account.get_default_burn_wallet(master_account)

      attrs = attrs |> Map.put(:from, burn_wallet.address)
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

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
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

      {:error, changeset} = TransferGate.get_or_insert(attrs)

      assert changeset.errors == [
               from:
                 {"can't be the address of a burn wallet",
                  [validation: :burn_wallet_as_sender_not_allowed]}
             ]
    end
  end

  describe "process/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.process(transfer)

      assert transfer.entry_uuid != nil
      assert transfer.status == Transfer.confirmed()
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      attrs = Map.put(attrs, :amount, 1_000_000)
      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.process(transfer)

      assert transfer.status == Transfer.failed()
      assert transfer.error_code == "insufficient_funds"
      assert transfer.error_description == nil

      assert transfer.error_data == %{
               "address" => attrs[:from],
               "amount_to_debit" => 1_000_000,
               "current_amount" => 100_000,
               "token_id" => attrs[:token_id]
             }

      assert transfer.status == Transfer.failed()
    end

    test "returns the previously inserted transfer", attrs do
      assert Transfer |> Repo.all() |> length() == 2

      {:ok, transfer_1} = TransferGate.get_or_insert(attrs)
      transfer_1 = TransferGate.process(transfer_1)

      assert transfer_1.entry_uuid != nil
      assert transfer_1.status == Transfer.confirmed()

      transfer_2 = TransferGate.process(transfer_1)

      assert transfer_2.entry_uuid != nil
      assert transfer_2.status == Transfer.confirmed()
      assert transfer_1.uuid == transfer_2.uuid
      assert Transfer |> Repo.all() |> length() == 3
    end
  end

  describe "genesis/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransferGate.get_or_insert(attrs)
      transfer = TransferGate.genesis(transfer)

      assert transfer.status == Transfer.confirmed()
      assert transfer.entry_uuid != nil
    end
  end
end
