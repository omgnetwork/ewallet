defmodule EWalletDB.TransactionConsumptionTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.TransactionConsumption

  describe "TransactionConsumption factory" do
    test_has_valid_factory TransactionConsumption
  end

  describe "get/1" do
    test "returns an existing transaction consumption" do
      inserted = insert(:transaction_consumption)
      consumption = TransactionConsumption.get(inserted.id)
      assert consumption.id == inserted.id
    end

    test "returns nil if the transaction consumption does not exist" do
      consumption = TransactionConsumption.get("unknown")
      assert consumption == nil
    end
  end

  describe "get/2" do
    test "returns nil if the transaction consumption does not exist" do
      consumption = TransactionConsumption.get("unknown")
      assert consumption == nil
    end

    test "preloads the specified association" do
      inserted = insert(:transaction_consumption)
      consumption = TransactionConsumption.get(inserted.id, preload: [:minted_token])
      assert consumption.id == inserted.id
      assert consumption.minted_token != nil
    end
  end

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # t1 and t2 have expiration dates in the past
      t1 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      t2 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -600, :seconds))
      t3 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 600, :seconds))
      t4 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 160, :seconds))

      # They are still valid since we haven't made them expired yet
      assert TransactionConsumption.expired?(t1) == false
      assert TransactionConsumption.expired?(t2) == false
      assert TransactionConsumption.expired?(t3) == false
      assert TransactionConsumption.expired?(t4) == false

      TransactionConsumption.expire_all()

      # Reload all the records
      t1 = TransactionConsumption.get(t1.id)
      t2 = TransactionConsumption.get(t2.id)
      t3 = TransactionConsumption.get(t3.id)
      t4 = TransactionConsumption.get(t4.id)

      # Now t1 and t2 are expired
      assert TransactionConsumption.expired?(t1) == true
      assert TransactionConsumption.expired?(t2) == true
      assert TransactionConsumption.expired?(t3) == false
      assert TransactionConsumption.expired?(t4) == false
    end

    test "sets the expired_at field" do
      now = NaiveDateTime.utc_now()
      t = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :seconds))
      TransactionConsumption.expire_all()
      t = TransactionConsumption.get(t.id)

      assert TransactionConsumption.expired?(t) == true
      assert t.expired_at != nil
    end
  end

  describe "all_active_for_request" do
    test "it returns all pending and confirmed consumptions for the given request" do
      request = insert(:transaction_request)
      _consumption_1 = insert(:transaction_consumption,
        transaction_request_id: request.id,
        status: "pending"
      )
      consumption_2 = insert(:transaction_consumption,
        transaction_request_id: request.id,
        status: "confirmed"
      )
      _consumption_3 = insert(:transaction_consumption,
        transaction_request_id: request.id,
        status: "failed"
      )
      _consumption_4 = insert(:transaction_consumption,
        transaction_request_id: request.id,
        status: "expired"
      )
      consumption_5 = insert(:transaction_consumption,
        transaction_request_id: request.id,
        status: "confirmed"
      )

      consumptions = TransactionConsumption.all_active_for_request(request.id)

      assert length(consumptions) == 2
      assert consumption_2 in consumptions == true
      assert consumption_5 in consumptions == true
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid TransactionConsumption, :id
    test_insert_generate_timestamps TransactionConsumption
    test_insert_prevent_blank TransactionConsumption, :amount
    test_insert_prevent_blank TransactionConsumption, :idempotency_token
    test_insert_prevent_blank TransactionConsumption, :transaction_request_id
    test_insert_prevent_blank TransactionConsumption, :balance_address
    test_insert_prevent_blank TransactionConsumption, :minted_token_id

    test "sets the status to 'pending'" do
      {:ok, inserted} = :transaction_consumption |> params_for() |> TransactionConsumption.insert()
      assert inserted.status == "pending"
    end
  end

  describe "approve/1" do
    test "approves the consumption" do
      consumption = insert(:transaction_consumption)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.approve(consumption)
      assert consumption.status == "approved"
    end
  end

  describe "reject/1" do
    test "rejects the consumption" do
      consumption = insert(:transaction_consumption)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.reject(consumption)
      assert consumption.status == "rejected"
    end
  end

  describe "confirm/2" do
    test "confirms the consumption" do
      consumption = insert(:transaction_consumption)
      transfer = insert(:transfer)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.confirm(consumption, transfer)
      assert consumption.status == "confirmed"
    end
  end

  describe "fail/2" do
    test "fails the consumption" do
      consumption = insert(:transaction_consumption)
      transfer = insert(:transfer)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.fail(consumption, transfer)
      assert consumption.status == "failed"
    end
  end

  describe "expired?/1" do
    test "returns true if valid" do
      consumption = insert(:transaction_consumption)
      assert TransactionConsumption.expired?(consumption) == false
    end

    test "returns false if expired" do
      consumption = insert(:transaction_consumption, status: "expired")
      assert TransactionConsumption.expired?(consumption) == true
    end
  end
end
