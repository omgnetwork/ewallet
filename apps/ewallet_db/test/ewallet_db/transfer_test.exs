defmodule EWalletDB.TransferTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Transfer

  describe "Transfer factory" do
    test_has_valid_factory Transfer
    test_encrypted_map_field Transfer, "transfer", :metadata
    test_encrypted_map_field Transfer, "transfer", :payload
    test_encrypted_map_field Transfer, "transfer", :ledger_response
  end

  describe "get_or_insert/1" do
    test "inserts a new transfer when idempotency token does not exist" do
      {:ok, transfer} = :transfer |> params_for() |> Transfer.get_or_insert()

      assert transfer.id != nil
      assert transfer.type == Transfer.internal
    end

    test "retrieves an existing transfer when idempotency token exists" do
      params = :transfer |> params_for()
      {:ok, inserted_transfer} = params |> Transfer.get_or_insert()
      {:ok, transfer} = params |> Transfer.get_or_insert()

      assert transfer.id == inserted_transfer.id
    end
  end

  describe "get/1" do
    test "retrieves a transfer by idempotency token" do
      {:ok, inserted_transfer} = :transfer |> params_for() |> Transfer.get_or_insert()
      transfer = Transfer.get(inserted_transfer.idempotency_token)

      assert transfer.id == inserted_transfer.id
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid Transfer, :id
    test_insert_generate_timestamps Transfer
    test_insert_prevent_blank Transfer, :payload
    test_insert_prevent_blank Transfer, :idempotency_token

    test "inserts a transfer if it does not existing" do
      assert Repo.all(Transfer) == []
      {:ok, transfer} =
        :transfer
        |> params_for()
        |> Transfer.insert
      transfers =
        Transfer |> Repo.all() |> Repo.preload([:from_balance, :to_balance, :minted_token])

      assert transfers == [transfer]
    end

    test "returns the existing transfer without error if already existing" do
      assert Repo.all(Transfer) == []
      {:ok, inserted_transfer} =
        :transfer |> params_for(idempotency_token: "123") |> Transfer.insert
      {:ok, transfer} = :transfer |> params_for(idempotency_token: "123") |> Transfer.insert

      assert inserted_transfer == transfer
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Transfer) == []
      {res, changeset} = %{idempotency_token: nil, payload: %{}} |> Transfer.insert
      assert res == :error
      assert changeset.errors == [idempotency_token: {"can't be blank", [validation: :required]},
                                  amount: {"can't be blank", [validation: :required]},
                                  minted_token_id: {"can't be blank",
                                                             [validation: :required]},
                                  to: {"can't be blank", [validation: :required]},
                                  from: {"can't be blank", [validation: :required]}]
    end
  end

  describe "confirm/2" do
    test "confirms a transfer" do
      {:ok, inserted_transfer} = :transfer |> params_for() |> Transfer.get_or_insert()
      assert inserted_transfer.status == Transfer.pending
      transfer = Transfer.confirm(inserted_transfer, %{ledger: "response"})
      assert transfer.id == inserted_transfer.id
      assert transfer.status == Transfer.confirmed
      assert transfer.ledger_response == %{"ledger" => "response"}
    end
  end

  describe "fail/2" do
    test "sets a transfer as failed" do
      {:ok, inserted_transfer} = :transfer |> params_for() |> Transfer.get_or_insert()
      assert inserted_transfer.status == Transfer.pending
      transfer = Transfer.fail(inserted_transfer, %{ledger: "response"})
      assert transfer.id == inserted_transfer.id
      assert transfer.status == Transfer.failed
      assert transfer.ledger_response == %{"ledger" => "response"}
    end
  end
end
