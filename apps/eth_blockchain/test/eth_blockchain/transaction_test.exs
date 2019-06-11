# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.TransactionTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.Transaction
  alias Keychain.Wallet

  setup state do
    {:ok, {address, _key}} = Wallet.generate()
    Map.put(state, :valid_sender, address)
  end

  describe "send_eth/3" do
    test "generates an eth transaction with the given adapter spec", state do
      {resp, _data} =
        Transaction.send_eth(
          {state[:valid_sender], state[:addr_1], 100},
          :dumb,
          state[:pid]
        )

      assert resp == :ok
    end

    test "returns an `invalid_parameter` error when the from address is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_eth(
                 {"0x01", state[:addr_1], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the to address is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_eth(
                 {state[:addr_0], "0x01", 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the amount is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_eth(
                 {state[:addr_0], state[:addr_1], 1.23},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_address` error when wallet is does not exist", state do
      assert {:error, :invalid_address} ==
               Transaction.send_eth(
                 {state[:addr_0], state[:addr_1], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Transaction.send_eth(
                 {state[:valid_sender], state[:addr_1], 100},
                 :blah,
                 state[:pid]
               )
    end
  end

  describe "send_token/3" do
    test "generates an eth transaction with the given adapter spec", state do
      {resp, _data} =
        Transaction.send_token(
          {state[:valid_sender], state[:addr_1], 100, state[:addr_2], 100},
          :dumb,
          state[:pid]
        )

      assert resp == :ok
    end

    test "returns an `invalid_parameter` error when the from address is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_token(
                 {"0x01", state[:addr_1], 100, state[:addr_2], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the to address is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_token(
                 {state[:addr_0], "0x01", 100, state[:addr_2], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the amount is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_token(
                 {state[:addr_0], state[:addr_1], 1.23, state[:addr_2], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the contract address is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_token(
                 {state[:addr_0], state[:addr_1], 100, "0x01", 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_parameter` error when the gas price is invalid", state do
      assert {:error, :invalid_parameter} ==
               Transaction.send_token(
                 {state[:addr_0], state[:addr_1], 100, state[:addr_2], 1.23},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an `invalid_address` error when wallet is does not exist", state do
      assert {:error, :invalid_address} ==
               Transaction.send_token(
                 {state[:addr_0], state[:addr_1], 100, state[:addr_2], 100},
                 :dumb,
                 state[:pid]
               )
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Transaction.send_token(
                 {state[:valid_sender], state[:addr_1], 100, state[:addr_2], 100},
                 :blah,
                 state[:pid]
               )
    end
  end
end
