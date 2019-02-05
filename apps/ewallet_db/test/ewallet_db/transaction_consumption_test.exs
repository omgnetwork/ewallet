# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.TransactionConsumptionTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWalletDB.TransactionConsumption

  describe "TransactionConsumption factory" do
    test_has_valid_factory(TransactionConsumption)
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
      consumption = TransactionConsumption.get(inserted.id, preload: [:token])
      assert consumption.id == inserted.id
      assert consumption.token != nil
    end
  end

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # t1 and t2 have expiration dates in the past
      t1 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :second))

      t2 =
        insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -600, :second))

      t3 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 600, :second))

      t4 = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, 160, :second))

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
      t = insert(:transaction_consumption, expiration_date: NaiveDateTime.add(now, -60, :second))
      TransactionConsumption.expire_all()
      t = TransactionConsumption.get(t.id)

      assert TransactionConsumption.expired?(t) == true
      assert t.expired_at != nil
    end
  end

  describe "all_active_for_request" do
    test "it returns all pending and confirmed consumptions for the given request" do
      request = insert(:transaction_request)

      _consumption_1 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "pending",
          originator: nil
        )

      consumption_2 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed",
          originator: nil
        )

      _consumption_3 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "failed",
          originator: nil
        )

      _consumption_4 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "expired",
          originator: nil
        )

      consumption_5 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed",
          originator: nil
        )

      consumptions = TransactionConsumption.all_active_for_request(request.uuid)

      assert length(consumptions) == 2
      assert consumption_2 in consumptions == true
      assert consumption_5 in consumptions == true
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(TransactionConsumption, :uuid)
    test_insert_generate_external_id(TransactionConsumption, :id, "txc_")
    test_insert_generate_timestamps(TransactionConsumption)
    test_insert_prevent_blank(TransactionConsumption, :idempotency_token)
    test_insert_prevent_blank(TransactionConsumption, :transaction_request_uuid)
    test_insert_prevent_blank(TransactionConsumption, :wallet_address)
    test_insert_prevent_blank(TransactionConsumption, :token_uuid)

    test "sets the status to 'pending'" do
      {:ok, inserted} =
        :transaction_consumption |> params_for() |> TransactionConsumption.insert()

      assert inserted.status == "pending"
    end

    test "fails with a duplicated correlation ID" do
      {:ok, _consumption_1} =
        :transaction_consumption
        |> params_for(correlation_id: "123")
        |> TransactionConsumption.insert()

      {res, changeset} =
        :transaction_consumption
        |> params_for(correlation_id: "123")
        |> TransactionConsumption.insert()

      assert res == :error

      assert changeset.errors == [
               correlation_id:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "transaction_consumption_correlation_id_index"
                  ]}
             ]
    end
  end

  describe "approve/1" do
    test "approves the consumption" do
      consumption = insert(:transaction_consumption)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.approve(consumption, %System{})
      assert consumption.status == "approved"
    end
  end

  describe "reject/1" do
    test "rejects the consumption" do
      consumption = insert(:transaction_consumption)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.reject(consumption, %System{})
      assert consumption.status == "rejected"
    end
  end

  describe "confirm/2" do
    test "confirms the consumption" do
      consumption = insert(:transaction_consumption)
      transaction = insert(:transaction)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.confirm(consumption, transaction)
      assert consumption.status == "confirmed"
    end
  end

  describe "fail/2" do
    test "fails the consumption" do
      consumption = insert(:transaction_consumption)
      transaction = insert(:transaction)
      assert consumption.status == "pending"
      consumption = TransactionConsumption.fail(consumption, transaction)
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
