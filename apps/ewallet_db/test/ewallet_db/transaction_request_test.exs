defmodule EWalletDB.TransactionRequestTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.TransactionRequest

  describe "TransactionRequest factory" do
    test_has_valid_factory(TransactionRequest)
  end

  describe "get/1" do
    test "returns an existing transaction request" do
      inserted = insert(:transaction_request)
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
      request = TransactionRequest.get("unknown", preload: [:token])
      assert request == nil
    end

    test "preloads the specified association" do
      inserted = insert(:transaction_request)
      request = TransactionRequest.get(inserted.id, preload: [:token])
      assert request.id == inserted.id
      assert request.token.id != nil
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
      assert t.expiration_reason == "expired_transaction_request"
    end
  end

  describe "get_with_lock/1" do
    test "gets a transaction request" do
      inserted = insert(:transaction_request)
      request = TransactionRequest.get_with_lock(inserted.id)
      assert request.uuid == inserted.uuid
    end
  end

  describe "touch/1" do
    test "updates the updated_at field" do
      request = insert(:transaction_request)
      {:ok, updated} = TransactionRequest.touch(request)
      assert NaiveDateTime.compare(updated.updated_at, request.updated_at) == :gt
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(TransactionRequest, :uuid)
    test_insert_generate_external_id(TransactionRequest, :id, "txr_")
    test_insert_generate_timestamps(TransactionRequest)
    test_insert_prevent_blank(TransactionRequest, :type)
    test_insert_prevent_blank(TransactionRequest, :token_uuid)
    test_insert_prevent_duplicate(TransactionRequest, :correlation_id)

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

    test "allows creation with an amount equal to nil" do
      {res, _inserted} =
        :transaction_request
        |> params_for(amount: nil)
        |> TransactionRequest.insert()

      assert res == :ok
    end

    test "allows creation with 'allow_amount_override=true' and nil amount" do
      {res, _inserted} =
        :transaction_request
        |> params_for(allow_amount_override: true, amount: nil)
        |> TransactionRequest.insert()

      assert res == :ok
    end

    test "prevents creation with 'allow_amount_override=false' and nil amount" do
      {:error, changeset} =
        :transaction_request
        |> params_for(allow_amount_override: false, amount: nil)
        |> TransactionRequest.insert()

      assert changeset.errors == [
               {:amount, {"needs to be set if amount override is not allowed.", []}}
             ]
    end
  end

  describe "valid?/1" do
    test "returns true if valid" do
      request = insert(:transaction_request)
      assert TransactionRequest.valid?(request) == true
    end

    test "returns false if expired" do
      request = insert(:transaction_request, status: "expired")
      assert TransactionRequest.valid?(request) == false
    end
  end

  describe "expired?/1" do
    test "returns true if valid" do
      request = insert(:transaction_request)
      assert TransactionRequest.expired?(request) == false
    end

    test "returns false if expired" do
      request = insert(:transaction_request, status: "expired")
      assert TransactionRequest.expired?(request) == true
    end
  end

  describe "expiration_from_lifetime/1" do
    test "returns nil if not require_confirmation" do
      request = insert(:transaction_request, require_confirmation: false)
      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if no consumption lifetime" do
      request =
        insert(:transaction_request, require_confirmation: true, consumption_lifetime: nil)

      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if consumption lifetime is equal to 0" do
      request = insert(:transaction_request, require_confirmation: true, consumption_lifetime: 0)
      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns the expiration date based on consumption_lifetime" do
      now = NaiveDateTime.utc_now()

      request =
        insert(
          :transaction_request,
          require_confirmation: true,
          consumption_lifetime: 1_000
        )

      date = TransactionRequest.expiration_from_lifetime(request)
      assert NaiveDateTime.compare(date, now) == :gt
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

  describe "expire_if_past_expiration_date/1" do
    test "does nothing if expiration date is not set" do
      request = insert(:transaction_request, expiration_date: nil)
      {res, request} = TransactionRequest.expire_if_past_expiration_date(request)
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "does nothing if expiration date is not past" do
      future_date = NaiveDateTime.add(NaiveDateTime.utc_now(), 60, :second)
      request = insert(:transaction_request, expiration_date: future_date)
      {res, request} = TransactionRequest.expire_if_past_expiration_date(request)
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "expires the request if expiration date is past" do
      past_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -60, :second)
      request = insert(:transaction_request, expiration_date: past_date)
      {res, request} = TransactionRequest.expire_if_past_expiration_date(request)
      assert res == :ok
      assert TransactionRequest.expired?(request) == true
    end
  end

  describe "expire_if_max_consumption/1" do
    test "touches the request if max_consumptions is equal to nil" do
      request = insert(:transaction_request, max_consumptions: nil)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert TransactionRequest.expired?(updated_request) == false
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions is equal to 0" do
      request = insert(:transaction_request, max_consumptions: 0)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions has not been reached" do
      request = insert(:transaction_request, max_consumptions: 3)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "expires the request if max_consumptions has been reached" do
      request = insert(:transaction_request, max_consumptions: 2)

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert updated_request.expired_at != nil
      assert updated_request.expiration_reason == "max_consumptions_reached"
      assert TransactionRequest.valid?(updated_request) == false
      assert TransactionRequest.expired?(updated_request) == true
    end
  end
end
