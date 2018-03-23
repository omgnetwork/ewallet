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

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # t1 and t2 have expiration dates in the past
      t1 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      t2 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -600, :seconds))
      t3 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, 600, :seconds))
      t4 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, 160, :seconds))

      # They are still valid since we haven't made them expired yet
      assert TransactionRequest.expired?(t1) == false
      assert TransactionRequest.expired?(t2) == false
      assert TransactionRequest.expired?(t3) == false
      assert TransactionRequest.expired?(t4) == false

      TransactionRequest.expire_all()

      # Reload all the records
      t1 = TransactionRequest.get(t1.id)
      t2 = TransactionRequest.get(t2.id)
      t3 = TransactionRequest.get(t3.id)
      t4 = TransactionRequest.get(t4.id)

      # Now t1 and t2 are expired
      assert TransactionRequest.expired?(t1) == true
      assert TransactionRequest.expired?(t2) == true
      assert TransactionRequest.expired?(t3) == false
      assert TransactionRequest.expired?(t4) == false
    end

    test "sets the expiration reason" do
      now = NaiveDateTime.utc_now()
      t = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      TransactionRequest.expire_all()
      t = TransactionRequest.get(t.id)

      assert TransactionRequest.expired?(t) == true
      assert t.expired_at != nil
      assert t.expiration_reason == "expired_request"
    end
  end

  describe "get_with_lock/1" do
    test "gets a transaction request" do
      {:ok, inserted} = :transaction_request |> params_for() |> TransactionRequest.insert()
      request = TransactionRequest.get_with_lock(inserted.id)
      assert request.id == inserted.id
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid TransactionRequest, :id
    test_insert_generate_timestamps TransactionRequest
    test_insert_prevent_blank TransactionRequest, :type
    test_insert_prevent_all_blank TransactionRequest, [:user_id, :account_id]
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

  describe "expire/2" do
    test "expires the request" do
      now = NaiveDateTime.utc_now()
      t = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      assert TransactionRequest.expired?(t) == false

      TransactionRequest.expire(t, "testing")

      t = TransactionRequest.get(t.id)
      assert TransactionRequest.expired?(t) == true
      assert t.expired_at != nil
      assert t.expiration_reason == "testing"
    end
  end

  describe "expire_if_max_consumption/1" do

  end
end
