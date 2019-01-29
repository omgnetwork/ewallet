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

defmodule EWalletDB.ExchangePairTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.ExchangePair
  alias ActivityLogger.System

  describe "ExchangePair factory" do
    test_has_valid_factory(ExchangePair)
  end

  describe "insert/1" do
    test_insert_generate_uuid(ExchangePair, :uuid)
    test_insert_generate_external_id(ExchangePair, :id, "exg_")
    test_insert_prevent_blank(ExchangePair, :rate)
    test_insert_prevent_blank_assoc(ExchangePair, :from_token)
    test_insert_prevent_blank_assoc(ExchangePair, :to_token)
    test_insert_generate_timestamps(ExchangePair)

    test "allows inserting existing pairs if the existing pairs are soft-deleted" do
      {:ok, pair} = :exchange_pair |> insert() |> ExchangePair.delete(%System{})

      attrs = %{
        from_token_uuid: pair.from_token_uuid,
        to_token_uuid: pair.to_token_uuid,
        rate: 999,
        originator: %System{}
      }

      {res, inserted} = ExchangePair.insert(attrs)

      assert res == :ok
      assert inserted.from_token_uuid == attrs.from_token_uuid
      assert inserted.to_token_uuid == attrs.to_token_uuid
      assert inserted.rate == attrs.rate
    end

    test "prevents from_token_uuid and to_token_uuid having the same value" do
      omg = insert(:token)

      attrs = %{
        from_token_uuid: omg.uuid,
        to_token_uuid: omg.uuid,
        rate: 1.00,
        originator: %System{}
      }

      {res, changeset} = ExchangePair.insert(attrs)

      assert res == :error

      assert changeset.errors == [
               {:to_token_uuid,
                {"can't have the same value as `from_token_uuid`",
                 [validation: :different_values]}}
             ]
    end

    test "prevents inserting of an existing pair" do
      pair = insert(:exchange_pair)

      attrs = %{
        from_token_uuid: pair.from_token_uuid,
        to_token_uuid: pair.to_token_uuid,
        rate: 999,
        originator: %System{}
      }

      {res, changeset} = ExchangePair.insert(attrs)

      assert res == :error

      assert changeset.errors == [
               from_token:
                 {"has already been taken",
                  [
                    constraint: :unique,
                    constraint_name: "exchange_pair_from_token_uuid_to_token_uuid_index"
                  ]}
             ]
    end

    test "prevents setting exchange rate to 0" do
      params = params_for(:exchange_pair, rate: 0)
      {res, changeset} = ExchangePair.insert(params)

      assert res == :error

      assert changeset.errors ==
               [
                 rate:
                   {"must be greater than %{number}",
                    [validation: :number, kind: :greater_than, number: 0]}
               ]
    end

    test "prevents setting exchange rate to a negative number" do
      params = params_for(:exchange_pair, rate: -1)
      {res, changeset} = ExchangePair.insert(params)

      assert res == :error

      assert changeset.errors ==
               [
                 rate:
                   {"must be greater than %{number}",
                    [validation: :number, kind: :greater_than, number: 0]}
               ]
    end
  end

  describe "update/2" do
    test_update_field_ok(ExchangePair, :rate, 2.00, 9.99)

    test_update_prevents_changing(
      ExchangePair,
      :from_token_uuid,
      insert(:token).uuid,
      insert(:token).uuid
    )

    test_update_prevents_changing(
      ExchangePair,
      :to_token_uuid,
      insert(:token).uuid,
      insert(:token).uuid
    )
  end

  describe "deleted?/1" do
    test_deleted_checks_nil_deleted_at(ExchangePair)
  end

  describe "delete/1" do
    test_delete_causes_record_deleted(ExchangePair)
  end

  describe "restore/1" do
    test_restore_causes_record_undeleted(ExchangePair)

    test "returns :exchange_pair_already_exists error when an undeleted pair already exists" do
      omg = insert(:token)
      eth = insert(:token)

      _active = insert(:exchange_pair, from_token: omg, to_token: eth)

      deleted =
        insert(
          :exchange_pair,
          from_token: omg,
          to_token: eth,
          deleted_at: NaiveDateTime.utc_now()
        )

      {res, code} = ExchangePair.restore(deleted, %System{})

      assert res == :error
      assert code == :exchange_pair_already_exists
    end
  end

  describe "touch/1" do
    test "touches the exchange pair's updated_at" do
      inserted = insert(:exchange_pair)
      {res, touched} = ExchangePair.touch(inserted, %System{})

      assert res == :ok
      assert NaiveDateTime.compare(touched.updated_at, inserted.updated_at) == :gt
    end
  end

  describe "get_name/1" do
    test "returns the exchange pair name" do
      abc = insert(:token, symbol: "ABC")
      xyz = insert(:token, symbol: "XYZ")
      pair = insert(:exchange_pair, from_token: abc, to_token: xyz)

      assert ExchangePair.get_name(pair) == "ABC/XYZ"
    end
  end

  describe "fetch_exchangable_pair/3" do
    test "returns {:ok, pair} if the tokens match a pair" do
      omg = insert(:token)
      eth = insert(:token)
      inserted_pair = insert(:exchange_pair, from_token: omg, to_token: eth)

      {res, pair} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :ok
      assert pair.uuid == inserted_pair.uuid
    end

    test "returns {:error, :exchange_pair_not_found} if a pair could not be found" do
      omg = insert(:token)
      eth = insert(:token)

      {res, code} = ExchangePair.fetch_exchangable_pair(omg, eth)

      assert res == :error
      assert code == :exchange_pair_not_found
    end
  end
end
