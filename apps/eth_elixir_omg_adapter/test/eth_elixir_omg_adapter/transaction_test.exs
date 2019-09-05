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

defmodule EthElixirOmgAdapter.TransactionTest do
  use EthElixirOmgAdapter.EthElixirOmgAdapterCase, async: true

  import Utils.Helpers.Encoding

  alias EthElixirOmgAdapter.{MockServer, Transaction, ResponseBody}
  alias Utils.Helpers.Crypto
  alias Keychain.Wallet

  @eth "0x0000000000000000000000000000000000000000"

  setup state do
    {:ok, {address, public_key}} = Wallet.generate()

    state
    |> Map.put(:valid_sender, address)
    |> Map.put(:public_key, public_key)
  end

  describe "get_deposit_tx_bytes/3" do
    test "get the transaction bytes for a deposit transaction" do
      address = Crypto.fake_eth_address()
      amount = 100
      currency = Crypto.fake_eth_address()
      {:ok, deposit_bytes} = Transaction.get_deposit_tx_bytes(address, amount, currency)

      expected_transaction = [
        [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]],
        [
          [from_hex(address), from_hex(currency), 100],
          [from_hex(@eth), from_hex(@eth), 0],
          [from_hex(@eth), from_hex(@eth), 0],
          [from_hex(@eth), from_hex(@eth), 0]
        ]
      ]

      assert deposit_bytes == ExRLP.encode(expected_transaction)
    end
  end

  describe "send/4" do
    test "successfuly sends a valid transaction", state do
      to = MockServer.success_receiver()

      {result, response} = Transaction.send(state[:valid_sender], to, 100, @eth)
      assert result == :ok

      assert response == %{
               :block_number => 123_000,
               :transaction_hash =>
                 "0xbdf562c24ace032176e27621073df58ce1c6f65de3b5932343b70ba03c72132d",
               :transaction_index => 111
             }
    end

    test "returns an error for an invalid sender" do
      sender = Crypto.fake_eth_address()
      to = MockServer.success_receiver()

      {result, error} = Transaction.send(sender, to, 100, @eth)
      assert result == :error
      assert error == :invalid_address
    end

    test "returns an error for an invalid transaction", state do
      to = Crypto.fake_eth_address()

      {result, response, message} = Transaction.send(state[:valid_sender], to, 100, @eth)
      %{"data" => %{"code" => code}} = ResponseBody.transaction_create_failure()
      assert result == :error
      assert response == :elixir_omg_bad_request
      assert message == [error_code: code]
    end
  end
end
