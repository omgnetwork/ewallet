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

defmodule EthBlockchain.ChildchainTest do
  use EthBlockchain.EthBlockchainCase, async: true

  import Utils.Helpers.Encoding

  alias EthBlockchain.{ABIEncoder, Adapter, Childchain, GasHelper, Helper}
  alias Keychain.Wallet
  alias Utils.Helpers.Crypto

  @eth Helper.default_address()

  setup state do
    {:ok, {address, public_key}} = Wallet.generate()

    state
    |> Map.put(:valid_sender, address)
    |> Map.put(:public_key, public_key)
  end

  describe "deposit/2" do
    test "submits an eth deposit transaction to ethereum", state do
      address = state[:valid_sender]
      amount = 100
      currency = @eth

      {res, encoded_trx} =
        Childchain.deposit(
          %{to: address, amount: amount, currency: currency, childchain_identifier: :elixir_omg},
          state[:adapter_opts]
        )

      assert res == :ok

      {:ok, tx_bytes} =
        Adapter.childchain_call(
          {:get_deposit_tx_bytes, address, amount, currency},
          state[:adapter_opts]
        )

      {:ok, encoded_abi_data} = ABIEncoder.child_chain_eth_deposit(tx_bytes)

      {:ok, contract_address} =
        Adapter.childchain_call({:get_contract_address}, state[:adapter_opts])

      trx = decode_transaction_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == encoded_abi_data
      assert to_hex(sender_public_key) == "0x" <> state[:public_key]
      assert trx.gas_limit == GasHelper.get_gas_limit_or_default(:child_chain_deposit_eth, %{})
      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == amount
      assert to_hex(trx.to) == contract_address
    end

    test "submits an erc20 deposit transaction to ethereum", state do
      address = state[:valid_sender]
      amount = 100
      currency = Crypto.fake_eth_address()

      {res, encoded_trx} =
        Childchain.deposit(
          %{to: address, amount: amount, currency: currency, childchain_identifier: :elixir_omg},
          state[:adapter_opts]
        )

      assert res == :ok

      {:ok, tx_bytes} =
        Adapter.childchain_call(
          {:get_deposit_tx_bytes, address, amount, currency},
          state[:adapter_opts]
        )

      {:ok, encoded_abi_data} = ABIEncoder.child_chain_erc20_deposit(tx_bytes)

      {:ok, contract_address} =
        Adapter.childchain_call({:get_contract_address}, state[:adapter_opts])

      trx = decode_transaction_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == encoded_abi_data
      assert to_hex(sender_public_key) == "0x" <> state[:public_key]
      assert trx.gas_limit == GasHelper.get_gas_limit_or_default(:child_chain_deposit_token, %{})
      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 0
      assert to_hex(trx.to) == contract_address
    end

    test "returns an error when given an invalid childchain identifier", state do
      {res, error} =
        Childchain.deposit(%{
          to: state[:valid_sender],
          amount: 100,
          currency: @eth,
          childchain_identifier: :invalid
        })

      assert res == :error
      assert error == :childchain_not_supported
    end
  end

  describe "send/2" do
    test "successfuly submit a transfer transaction to the childchain", state do
      address = state[:valid_sender]
      amount = 100
      currency = @eth

      {res, tx_hash, tx_index, blk_num} =
        Childchain.send(
          %{
            from: address,
            to: state[:addr_1],
            amount: amount,
            currency: currency,
            childchain_identifier: :elixir_omg
          },
          state[:adapter_opts]
        )

      assert res == :ok
      assert tx_hash == "0xbdf562c24ace032176e27621073df58ce1c6f65de3b5932343b70ba03c72132d"
      assert tx_index == 111
      assert blk_num == 123_000
    end

    test "returns an error when given an invalid childchain identifier", state do
      {res, error} =
        Childchain.send(
          %{
            from: address,
            to: state[:addr_1],
            amount: amount,
            currency: currency,
            childchain_identifier: :invalid
          },
          state[:adapter_opts]
        )

      assert res == :error
      assert error == :childchain_not_supported
    end
  end
end
