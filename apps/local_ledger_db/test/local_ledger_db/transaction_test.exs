defmodule LocalLedgerDB.TransactionTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.Transaction
  alias LocalLedgerDB.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias LocalLedgerDB.Errors.InsufficientFundsError

  @uuid_regex ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  defp build_valid_transaction do
    build_transaction(%{})
  end

  defp build_transaction(attrs) do
    Transaction.changeset(%Transaction{}, params_for(:transaction, attrs))
  end

  defp insert_valid_transaction do
    insert_transaction(%{})
  end

  defp insert_transaction(attrs, name \\ :transaction) do
    params = params_for(name, attrs)
    {_, transaction} = %Transaction{}
                       |> Transaction.changeset(params)
                       |> Repo.insert
    transaction
  end

  defp insert_transactions_with_amounts(credit, debit) do
    {:ok, entry} = :entry |> build |> Repo.insert
    {:ok, token} = :minted_token |> build |> Repo.insert
    {:ok, balance} = :balance |> build |> Repo.insert

    attrs = %{
      amount: credit,
      type: Transaction.credit_type,
      entry_id: entry.id,
      balance_address: balance.address,
      minted_token_friendly_id: token.friendly_id
    }

    insert_transaction(attrs, :empty_transaction)
    insert_transaction(%{attrs | amount: debit, type: Transaction.debit_type},
                       :empty_transaction)
    {token, balance}
  end

  describe "initialization" do
    test "generates a UUID in place of a regular ID" do
      transaction = insert_valid_transaction()

      assert String.match?(transaction.id, @uuid_regex)
    end

    test "generates the inserted_at and updated_at values" do
      transaction = insert_valid_transaction()

      assert transaction.inserted_at != nil
      assert transaction.updated_at != nil
    end
  end

  defp transfer(balance, token, amount, type) do
    {:ok, entry} = :entry |> build |> Repo.insert

    attrs = %{
      amount: amount, type: Transaction.credit_type, entry_id: entry.id,
      balance_address: balance.address, minted_token_friendly_id: token.friendly_id
    }

    insert_transaction(%{attrs | amount: amount, type: type},
                       :empty_transaction)
  end

  describe "validations" do
    test "has a valid factory" do
      transaction = build_valid_transaction()

      assert transaction.valid?
    end

    test "prevents creation of a transaction without an amount" do
      transaction = build_transaction(%{amount: nil})

      refute transaction.valid?
      assert transaction.errors == [amount: {"can't be blank",
                                            [validation: :required]}]
    end

    test "prevents creation of a transaction without a type" do
      transaction = build_transaction(%{type: nil})

      refute transaction.valid?
      assert transaction.errors == [type: {"can't be blank",
                                          [validation: :required]}]
    end

    test "prevents creation of a transaction without a minted token friendly_id" do
      transaction = build_transaction(%{minted_token_friendly_id: nil})

      refute transaction.valid?
      assert transaction.errors == [minted_token_friendly_id:
                                    {"can't be blank",
                                    [validation: :required]}
                                   ]
    end

    test "prevents creation of a transaction without an invalid minted token" do
      transaction = insert_transaction(%{minted_token_friendly_id: "AAA"})

      refute transaction.valid?
      assert transaction.errors == [minted_token_friendly_id: {"does not exist", []}]
    end

    test "prevents creation of a transaction without a balance" do
      transaction = build_transaction(%{balance_address: nil})

      refute transaction.valid?
      assert transaction.errors == [balance_address: {"can't be blank",
                                                     [validation: :required]}]
    end

    test "prevents creation of a transaction without a non existing balance" do
      transaction = insert_transaction(%{balance_address: "123"})

      refute transaction.valid?
      assert transaction.errors == [balance_address: {"does not exist", []}]
    end

    test "prevents creation of a transaction without an entry" do
      assert_raise Postgrex.Error, ~r/violates not-null constraint/, fn ->
        insert_transaction(%{entry_id: nil})
      end
    end

    test "prevents creation of a transaction without a non existing entry" do
      transaction = insert_transaction(%{entry_id: UUID.generate})

      refute transaction.valid?
      assert transaction.errors == [entry_id: {"does not exist", []}]
    end
  end

  describe "#check_balance" do
    test "returns :ok if the balance has enough funds" do
      {token, balance} = insert_transactions_with_amounts(200, 100)
      res = Transaction.check_balance(%{amount: 80,
                                        friendly_id: token.friendly_id,
                                        address: balance.address})
      assert res == :ok
    end

    test "raises InsufficientFundsError if the balance does not
          have enough funds" do
      {token, balance} = insert_transactions_with_amounts(200, 130)

      assert_raise InsufficientFundsError, fn ->
        Transaction.check_balance(%{amount: 80,
                                    friendly_id: token.friendly_id,
                                    address: balance.address})
      end
    end
  end

  describe "calculate_all_balances/2" do
    test "returns the correct balances for each token" do
      {:ok, balance} = :balance |> build |> Repo.insert

      {:ok, omg} = :minted_token |> build(friendly_id: "OMG:209d3f5b-eab4-4906-9697-c482009fc865") |> Repo.insert
      {:ok, knc} = :minted_token |> build(friendly_id: "KNC:310-d3f5b-eab4-4906-9697-c482009fc865") |> Repo.insert
      {:ok, btc} = :minted_token |> build(friendly_id: "BTC:209d3f5b-eab4-4906-9697-c482009fc865") |> Repo.insert

      transfer(balance, omg, 100, Transaction.debit_type)
      transfer(balance, omg, 300, Transaction.credit_type)
      transfer(balance, omg, 500, Transaction.credit_type)
      transfer(balance, knc, 100, Transaction.credit_type)
      transfer(balance, btc, 100, Transaction.credit_type)
      transfer(balance, btc, 200, Transaction.credit_type)

      balances = Transaction.calculate_all_balances(balance.address)
      assert balances == %{"BTC:209d3f5b-eab4-4906-9697-c482009fc865" => 300, "KNC:310-d3f5b-eab4-4906-9697-c482009fc865" => 100, "OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 700}
    end
  end

  describe "calculate_all_balances/3" do
    test "returns the correct balance for the specified token" do
      {:ok, balance} = :balance |> build |> Repo.insert

      {:ok, omg} = :minted_token |> build(friendly_id: "OMG:209d3f5b-eab4-4906-9697-c482009fc865") |> Repo.insert
      {:ok, knc} = :minted_token |> build(friendly_id: "KNC:310-d3f5b-eab4-4906-9697-c482009fc865") |> Repo.insert

      transfer(balance, omg, 100, Transaction.debit_type)
      transfer(balance, omg, 300, Transaction.credit_type)
      transfer(balance, omg, 500, Transaction.credit_type)
      transfer(balance, knc, 100, Transaction.credit_type)

      balances = Transaction.calculate_all_balances(balance.address, %{
        friendly_id: "OMG:209d3f5b-eab4-4906-9697-c482009fc865"
      })
      assert balances == %{"OMG:209d3f5b-eab4-4906-9697-c482009fc865" => 700}
    end
  end

  describe "#calculate_current_amount" do
    test "returns the correct current balance amount" do
      {token, balance} = insert_transactions_with_amounts(200, 130)

      amount = Transaction.calculate_current_amount(balance.address,
                                                    token.friendly_id)
      assert amount == 70
    end
  end
end
