# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule LocalLedger.Transaction.ValidatorTest do
  use ExUnit.Case, async: true
  alias LocalLedger.Errors.{AmountNotPositiveError, InvalidAmountError, SameAddressError}
  alias LocalLedger.Transaction.Validator

  setup do
    %{
      alice: "address_alice",
      bob: "address_bob",
      omg: "tok_OMG_1234",
      eth: "tok_ETH_1234"
    }
  end

  defp entry(type, address, amount, token_id) do
    %{
      "type" => Atom.to_string(type),
      "address" => address,
      "amount" => amount,
      "token" => %{
        "id" => token_id
      }
    }
  end

  describe "validate_different_addresses/1" do
    test "returns entries if addresses are different", meta do
      entries = [
        entry(:debit, meta.alice, 100, meta.omg),
        entry(:credit, meta.bob, 100, meta.omg)
      ]

      assert Validator.validate_different_addresses(entries) == entries
    end

    test "returns entries if two entries have the same address but different tokens", meta do
      entries = [
        entry(:debit, meta.alice, 100, meta.omg),
        entry(:credit, meta.bob, 100, meta.omg),
        entry(:debit, meta.bob, 200, meta.eth),
        entry(:credit, meta.alice, 200, meta.eth)
      ]

      assert Validator.validate_different_addresses(entries) == entries
    end

    test "raises SameAddressError if two entries have the same address and token", meta do
      entries = [
        entry(:debit, meta.alice, 200, meta.omg),
        entry(:credit, meta.alice, 100, meta.omg),
        entry(:credit, meta.bob, 100, meta.omg)
      ]

      assert_raise SameAddressError, fn ->
        Validator.validate_different_addresses(entries)
      end
    end
  end

  describe "validate_zero_sum/1" do
    test "returns entries if the debit/credit sum for each token is zero", meta do
      entries = [
        entry(:debit, meta.alice, 35, meta.omg),
        entry(:credit, meta.bob, 35, meta.omg)
      ]

      assert Validator.validate_zero_sum(entries) == entries
    end

    test "raises InvalidAmountError if entries don't add up to zero", meta do
      entries = [
        entry(:debit, meta.bob, 10, meta.omg),
        entry(:credit, meta.alice, 999, meta.omg)
      ]

      assert_raise InvalidAmountError, fn ->
        Validator.validate_zero_sum(entries)
      end
    end

    test "raises InvalidAmountError if entries for any token don't add up to zero", meta do
      entries = [
        entry(:debit, meta.alice, 10, meta.omg),
        entry(:credit, meta.bob, 10, meta.omg),
        entry(:debit, meta.bob, 10, meta.eth),
        entry(:credit, meta.alice, 999, meta.eth)
      ]

      assert_raise InvalidAmountError, fn ->
        Validator.validate_zero_sum(entries)
      end
    end
  end

  describe "validate_positive_amounts/1" do
    test "returns entries if all entry amounts are greater than zero", meta do
      entries = [
        entry(:debit, meta.alice, 1, meta.omg),
        entry(:credit, meta.bob, 1, meta.omg),
        entry(:debit, meta.bob, 1_000_000_000, meta.eth),
        entry(:credit, meta.alice, 1_000_000_000, meta.eth)
      ]

      assert Validator.validate_positive_amounts(entries) == entries
    end

    test "raises AmountNotPositiveError if any entry amount zero", meta do
      entries = [
        entry(:debit, meta.alice, 1, meta.omg),
        entry(:debit, meta.alice, 0, meta.omg)
      ]

      assert_raise AmountNotPositiveError, fn ->
        Validator.validate_positive_amounts(entries)
      end
    end

    test "raises AmountNotPositiveError if any entry amount is less than zero", meta do
      entries = [
        entry(:debit, meta.alice, 1, meta.omg),
        entry(:credit, meta.bob, 1, meta.omg),
        entry(:debit, meta.bob, 1, meta.eth),
        entry(:credit, meta.alice, -1, meta.eth)
      ]

      assert_raise AmountNotPositiveError, fn ->
        Validator.validate_positive_amounts(entries)
      end
    end
  end
end
