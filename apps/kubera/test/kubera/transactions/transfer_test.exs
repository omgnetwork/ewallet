 defmodule Kubera.TransferTest do
  use ExUnit.Case
  use Kubera.MockCase
  import KuberaDB.Factory
  alias Kubera.Transactions
  alias KuberaDB.{Repo, MintedToken, Account, Transfer}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)

    {:ok, account1} = Account.insert(params_for(:account))
    {:ok, account2} = Account.insert(params_for(:account))
    {:ok, token} = MintedToken.insert(params_for(:minted_token))
    from = Account.get_primary_balance(account1)
    to = Account.get_primary_balance(account2)

    %{
      idempotency_token: UUID.generate(),
      from: from.address,
      to: to.address,
      minted_token_id: token.id,
      amount: 10,
      metadata: %{},
      payload: %{}
    }
  end

  describe "get_or_insert/1" do
    test "inserts a new internal transfer when not existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

      {:ok, inserted_transfer} = Transactions.Transfer.get_or_insert(attrs)

      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer.id == inserted_transfer.id
      assert transfer.type == Transfer.internal
    end

    test "gets a transfer if already existing", attrs do
      transfer = Transfer.get(attrs.idempotency_token)
      assert transfer == nil

      {:ok, inserted_transfer1} = Transactions.Transfer.get_or_insert(attrs)
      {:ok, inserted_transfer2} = Transactions.Transfer.get_or_insert(attrs)

      assert inserted_transfer1.id == inserted_transfer2.id
      assert Transfer |> Repo.all() |> length() == 1
    end
  end

  describe "process/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      mock_entry_insert_success fn ->
        {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
        {res, transfer} = Transactions.Transfer.process(transfer)
        transfer = Transfer.get(transfer.idempotency_token)

        assert res == :ok
        assert transfer.ledger_response == %{"data" => "from ledger"}
        assert transfer.status == Transfer.confirmed
      end
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      mock_entry_insert_fail fn ->
        {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
        {res, code, description} = Transactions.Transfer.process(transfer)
        transfer = Transfer.get(transfer.idempotency_token)

        assert res == :error
        assert code == "code"
        assert description == "description"
        assert transfer.status == Transfer.failed
      end
    end
  end

  describe "genesis/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      mock_entry_genesis_success fn ->
        {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
        {res, transfer} = Transactions.Transfer.genesis(transfer)
        transfer = Transfer.get(transfer.idempotency_token)

        assert res == :ok
        assert transfer.ledger_response == %{"data" => "from ledger"}
        assert transfer.status == Transfer.confirmed
      end
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      mock_entry_genesis_fail fn ->
        {:ok, transfer} = Transactions.Transfer.get_or_insert(attrs)
        {res, code, description} = Transactions.Transfer.genesis(transfer)
        transfer = Transfer.get(transfer.idempotency_token)

        assert res == :error
        assert code == "code"
        assert description == "description"
        assert transfer.status == Transfer.failed
      end
    end
  end
end
