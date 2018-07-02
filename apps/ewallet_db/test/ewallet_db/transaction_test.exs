defmodule EWalletDB.TransactionTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Transaction
  alias Ecto.UUID

  describe "Transaction factory" do
    test_has_valid_factory(Transaction)
    test_encrypted_map_field(Transaction, "transaction", :encrypted_metadata)
    test_encrypted_map_field(Transaction, "transaction", :payload)
  end

  describe "get_or_insert/1" do
    test "inserts a new transaction when idempotency token does not exist" do
      {:ok, transaction} = :transaction |> params_for() |> Transaction.get_or_insert()

      assert transaction.id != nil
      assert transaction.type == Transaction.internal()
    end

    test "retrieves an existing transaction when idempotency token exists" do
      params = :transaction |> params_for()
      {:ok, inserted_transaction} = params |> Transaction.get_or_insert()
      {:ok, transaction} = params |> Transaction.get_or_insert()

      assert transaction.id == inserted_transaction.id
    end
  end

  describe "get/1" do
    test "retrieves a transaction by idempotency token" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      transaction = Transaction.get_by_idempotency_token(inserted_transaction.idempotency_token)

      assert transaction.id == inserted_transaction.id
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(Transaction, :uuid)
    test_insert_generate_external_id(Transaction, :id, "txn_")
    test_insert_generate_timestamps(Transaction)
    test_insert_prevent_blank(Transaction, :payload)
    test_insert_prevent_blank(Transaction, :idempotency_token)
    test_default_metadata_fields(Transaction, "transaction")

    test "inserts a transaction if it does not existing" do
      assert Repo.all(Transaction) == []

      {:ok, transaction} =
        :transaction
        |> params_for()
        |> Transaction.insert()

      transactions =
        Transaction
        |> Repo.all()
        |> Repo.preload([:from_wallet, :to_wallet, :from_token, :to_token])

      assert transactions == [transaction]
    end

    test "returns the existing transaction without error if already existing" do
      assert Repo.all(Transaction) == []

      {:ok, inserted_transaction} =
        :transaction |> params_for(idempotency_token: "123") |> Transaction.insert()

      {:ok, transaction} =
        :transaction |> params_for(idempotency_token: "123") |> Transaction.insert()

      assert inserted_transaction == transaction
      assert Transaction |> Repo.all() |> length() == 1
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Transaction) == []
      {res, changeset} = %{idempotency_token: nil, payload: %{}} |> Transaction.insert()
      assert res == :error

      assert changeset.errors == [
               idempotency_token: {"can't be blank", [validation: :required]},
               from_amount: {"can't be blank", [validation: :required]},
               from_token_uuid: {"can't be blank", [validation: :required]},
               to_amount: {"can't be blank", [validation: :required]},
               to_token_uuid: {"can't be blank", [validation: :required]},
               to: {"can't be blank", [validation: :required]},
               from: {"can't be blank", [validation: :required]}
             ]
    end

    test "succeed with from_amount < 100_000_000_000_000_000_000_000_000_000_000_000" do
      {res, transaction} =
        :transaction
        |> params_for(from_amount: 99_999_999_999_999_999_999_999_999_999_999_999)
        |> Transaction.insert()

      assert res == :ok
      assert transaction.from_amount == 99_999_999_999_999_999_999_999_999_999_999_999
    end

    test "succeed with to_amount < 100_000_000_000_000_000_000_000_000_000_000_000" do
      {res, transaction} =
        :transaction
        |> params_for(to_amount: 99_999_999_999_999_999_999_999_999_999_999_999)
        |> Transaction.insert()

      assert res == :ok
      assert transaction.to_amount == 99_999_999_999_999_999_999_999_999_999_999_999
    end
  end

  describe "confirm/2" do
    test "confirms a transaction" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == Transaction.pending()
      local_ledger_uuid = UUID.generate()
      transaction = Transaction.confirm(inserted_transaction, local_ledger_uuid)
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.confirmed()
      assert transaction.local_ledger_uuid == local_ledger_uuid
    end
  end

  describe "fail/2" do
    test "sets a transaction as failed" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == Transaction.pending()
      transaction = Transaction.fail(inserted_transaction, "error", "desc")
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == "desc"
      assert transaction.error_data == nil
    end

    test "sets a transaction as failed with atom error" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == Transaction.pending()
      transaction = Transaction.fail(inserted_transaction, :error, "desc")
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == "desc"
      assert transaction.error_data == nil
    end

    test "sets a transaction as failed with error_data" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == Transaction.pending()
      transaction = Transaction.fail(inserted_transaction, "error", %{})
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == nil
      assert transaction.error_data == %{}
    end

    test "fails when from_amount is >= 100_000_000_000_000_000_000_000_000_000_000_000 (max 35 digits)" do
      {res, error} =
        :transaction
        |> params_for(from_amount: 100_000_000_000_000_000_000_000_000_000_000_000)
        |> Transaction.insert()

      assert res == :error

      assert error.errors == [
               from_amount:
                 {"must be less than %{number}",
                  [validation: :number, number: 100_000_000_000_000_000_000_000_000_000_000_000]}
             ]
    end

    test "fails when to_amount is >= 100_000_000_000_000_000_000_000_000_000_000_000 (max 35 digits)" do
      {res, error} =
        :transaction
        |> params_for(to_amount: 100_000_000_000_000_000_000_000_000_000_000_000)
        |> Transaction.insert()

      assert res == :error

      assert error.errors == [
               to_amount:
                 {"must be less than %{number}",
                  [validation: :number, number: 100_000_000_000_000_000_000_000_000_000_000_000]}
             ]
    end
  end
end
