defmodule EWalletDB.TransactionRequestTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.TransactionRequest

  describe "TransactionRequest factory" do
    test_has_valid_factory TransactionRequest
  end

  describe "get/1" do
    test "returns an existing transaction request" do
      {:ok, inserted} = :transaction_request |> params_for() |> TransactionRequest.insert()
      request = TransactionRequest.get(inserted.id)
      assert request.id == inserted.id
    end

    test "returns nil if the transaction request does not exist" do
      request = TransactionRequest.get("unknown")
      assert request == nil
    end
  end

  describe "get/2" do
    test "returns nil if the transaction request does not exist" do
      request = TransactionRequest.get("unknown", preload: [:minted_token])
      assert request == nil
    end

    test "preloads the specified association" do
      {:ok, inserted} = :transaction_request |> params_for() |> TransactionRequest.insert()
      request = TransactionRequest.get(inserted.id, preload: [:minted_token])
      assert request.id == inserted.id
      assert request.minted_token.id != nil
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid TransactionRequest, :id
    test_insert_generate_timestamps TransactionRequest
    test_insert_prevent_blank TransactionRequest, :type
    test_insert_prevent_blank TransactionRequest, :user_id
    test_insert_prevent_blank TransactionRequest, :minted_token_id
    test_insert_prevent_duplicate TransactionRequest, :correlation_id

    test "sets the status to 'valid'" do
      {:ok, inserted} = :transaction_request |> params_for() |> TransactionRequest.insert()
      assert inserted.status == "valid"
    end

    test "prevents creation with an invalid type" do
      {:error, changeset} =
        :transaction_request
        |> params_for(type: "fake")
        |> TransactionRequest.insert()
      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end
  end
end
