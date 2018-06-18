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

    {_, transaction} =
      %Transaction{}
      |> Transaction.changeset(params)
      |> Repo.insert()

    transaction
  end

  defp insert_transactions_with_amounts(credit, debit) do
    {:ok, entry} = :entry |> build |> Repo.insert()
    {:ok, token} = :token |> build |> Repo.insert()
    {:ok, balance} = :wallet |> build |> Repo.insert()

    attrs = %{
      amount: credit,
      type: Transaction.credit_type(),
      entry_uuid: entry.uuid,
      wallet_address: balance.address,
      token_id: token.id
    }

    insert_transaction(attrs, :empty_transaction)

    insert_transaction(
      %{attrs | amount: debit, type: Transaction.debit_type()},
      :empty_transaction
    )

    {token, balance}
  end

  defp transfer(balance, token, amount, type) do
    {:ok, entry} = :entry |> build |> Repo.insert()

    attrs = %{
      amount: amount,
      type: Transaction.credit_type(),
      entry_uuid: entry.uuid,
      wallet_address: balance.address,
      token_id: token.id
    }

    insert_transaction(%{attrs | amount: amount, type: type}, :empty_transaction)
  end

  describe "initialization" do
    test "generates a UUID" do
      transaction = insert_valid_transaction()

      assert String.match?(transaction.uuid, @uuid_regex)
    end

    test "generates the inserted_at and updated_at values" do
      transaction = insert_valid_transaction()

      assert transaction.inserted_at != nil
      assert transaction.updated_at != nil
    end
  end

  describe "validations" do
    test "has a valid factory" do
      transaction = build_valid_transaction()

      assert transaction.valid?
    end

    test "prevents creation of a transaction without an amount" do
      transaction = build_transaction(%{amount: nil})

      refute transaction.valid?
      assert transaction.errors == [amount: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a transaction without a type" do
      transaction = build_transaction(%{type: nil})

      refute transaction.valid?
      assert transaction.errors == [type: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a transaction without a token id" do
      transaction = build_transaction(%{token_id: nil})

      refute transaction.valid?
      assert transaction.errors == [token_id: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a transaction without an invalid token" do
      transaction = insert_transaction(%{token_id: "AAA"})

      refute transaction.valid?
      assert transaction.errors == [token_id: {"does not exist", []}]
    end

    test "prevents creation of a transaction without a balance" do
      transaction = build_transaction(%{wallet_address: nil})

      refute transaction.valid?
      assert transaction.errors == [wallet_address: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a transaction without a non existing balance" do
      transaction = insert_transaction(%{wallet_address: "123"})

      refute transaction.valid?
      assert transaction.errors == [wallet_address: {"does not exist", []}]
    end

    test "prevents creation of a transaction without an entry" do
      assert_raise Postgrex.Error, ~r/violates not-null constraint/, fn ->
        insert_transaction(%{entry_uuid: nil})
      end
    end

    test "prevents creation of a transaction without a non existing entry" do
      transaction = insert_transaction(%{entry_uuid: UUID.generate()})

      refute transaction.valid?
      assert transaction.errors == [entry_uuid: {"does not exist", []}]
    end
  end

  describe "check_balance/1" do
    test "returns :ok if the balance has enough funds" do
      {token, balance} = insert_transactions_with_amounts(200, 100)

      res =
        Transaction.check_balance(%{
          amount: 80,
          token_id: token.id,
          address: balance.address
        })

      assert res == :ok
    end

    test "raises InsufficientFundsError if the balance does not
          have enough funds" do
      {token, balance} = insert_transactions_with_amounts(200, 130)

      assert_raise InsufficientFundsError, fn ->
        Transaction.check_balance(%{
          amount: 80,
          token_id: token.id,
          address: balance.address
        })
      end
    end
  end

  describe "calculate_all_balances/2" do
    test "returns the correct wallets for each token" do
      {:ok, balance} = :wallet |> build |> Repo.insert()

      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()
      {:ok, btc} = :token |> build(id: "tok_BTC_789") |> Repo.insert()

      transfer(balance, omg, 100, Transaction.debit_type())
      transfer(balance, omg, 300, Transaction.credit_type())
      transfer(balance, omg, 500, Transaction.credit_type())
      transfer(balance, knc, 100, Transaction.credit_type())
      transfer(balance, btc, 100, Transaction.credit_type())
      transfer(balance, btc, 200, Transaction.credit_type())

      wallets = Transaction.calculate_all_balances(balance.address)
      assert wallets == %{"tok_BTC_789" => 300, "tok_KNC_456" => 100, "tok_OMG_123" => 700}
    end

    test "works even if the wallet only had debits" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()

      transfer(balance, omg, 100, Transaction.debit_type())
      transfer(balance, omg, 300, Transaction.debit_type())
      transfer(balance, omg, 500, Transaction.debit_type())

      wallets = Transaction.calculate_all_balances(balance.address)
      assert wallets == %{"tok_OMG_123" => -900}
    end

    test "returns the correct balance for the specified token" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Transaction.debit_type())
      transfer(balance, omg, 300, Transaction.credit_type())
      transfer(balance, omg, 500, Transaction.credit_type())
      transfer(balance, knc, 100, Transaction.credit_type())

      wallets =
        Transaction.calculate_all_balances(balance.address, %{
          token_id: "tok_OMG_123"
        })

      assert wallets == %{"tok_OMG_123" => 300 + 500 - 100}
    end

    test "calculates all wallets since specified date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Transaction.debit_type())
      transfer(balance, omg, 300, Transaction.credit_type())
      transfer(balance, omg, 500, Transaction.credit_type())
      transfer(balance, knc, 100, Transaction.credit_type())

      transactions = Repo.all(Transaction)
      transaction = Enum.at(transactions, 1)

      all_wallets = Transaction.calculate_all_balances(balance.address)

      wallets =
        Transaction.calculate_all_balances(balance.address, %{
          since: transaction.inserted_at
        })

      assert all_wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 300 + 500 - 100}
      assert wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 500}
    end

    test "calculates all wallets up to the specified date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Transaction.debit_type())
      transfer(balance, omg, 300, Transaction.credit_type())
      transfer(balance, omg, 500, Transaction.credit_type())
      transfer(balance, knc, 100, Transaction.credit_type())

      transactions = Repo.all(Transaction)
      transaction = Enum.at(transactions, 1)

      all_wallets = Transaction.calculate_all_balances(balance.address)

      wallets =
        Transaction.calculate_all_balances(balance.address, %{
          upto: transaction.inserted_at
        })

      assert all_wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 300 + 500 - 100}
      assert wallets == %{"tok_OMG_123" => 300 - 100}
    end

    test "calculates all wallets between the specified 'since' date and 'upto' date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()

      transfer(balance, omg, 300, Transaction.credit_type())
      transfer(balance, omg, 500, Transaction.credit_type())
      transfer(balance, omg, 100, Transaction.credit_type())
      transfer(balance, omg, 1200, Transaction.credit_type())
      transfer(balance, omg, 250, Transaction.credit_type())

      transactions = Repo.all(Transaction)
      transaction_1 = Enum.at(transactions, 1)
      transaction_2 = Enum.at(transactions, 3)

      all_wallets = Transaction.calculate_all_balances(balance.address)

      wallets =
        Transaction.calculate_all_balances(balance.address, %{
          since: transaction_1.inserted_at,
          upto: transaction_2.inserted_at
        })

      assert all_wallets == %{"tok_OMG_123" => 300 + 500 + 100 + 1200 + 250}
      assert wallets == %{"tok_OMG_123" => 100 + 1200}
    end
  end

  describe "#calculate_current_amount" do
    test "returns the correct current balance amount" do
      {token, balance} = insert_transactions_with_amounts(200, 130)

      amount = Transaction.calculate_current_amount(balance.address, token.id)
      assert amount == 70
    end
  end
end
