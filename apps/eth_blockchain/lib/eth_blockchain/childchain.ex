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

defmodule EthBlockchain.Childchain do
  @moduledoc false
  import Utils.Helpers.Encoding
  alias EthBlockchain.{Adapter, Helper}

  @eth EthBlockchain.Helper.default_address()

  # TODO: All the actual interactions with the childchain in the functions below should be extracted
  # to another subapp: EthElixirOMGAdapter
  def deposit(
        %{
          to: to,
          amount: amount,
          currency: currency_address,
          childchain_identifier: childchain_identifier
        } = attrs,
        adapter \\ nil,
        pid \\ nil
      ) do
    # check that childchain identifier is supported
    childchains = Application.get_env(:eth_blockchain, :childchains)

    childchain_identifier =
      childchain_identifier || Application.get_env(:eth_blockchain, :default_childchain)

    case Map.get(childchains, childchain_identifier) do
      nil ->
        {:error, :childchain_not_supported}

      %{contract_address: contract_address} ->
        deposit_to_child_chain(to, amount, currency_address, contract_address, adapter, pid)
    end
  end

  defp deposit_to_child_chain(to, amount, token \\ @eth, contract_address, adapter, pid)

  defp deposit_to_child_chain(to, amount, @eth, contract_address, adapter, pid) do
    tx_bytes =
      []
      |> EthBlockchain.Plasma.Transaction.new([
        {from_hex(to), from_hex(@eth), amount}
      ])
      |> EthBlockchain.Plasma.Transaction.encode()

    EthBlockchain.Transaction.deposit_eth(
      %{tx_bytes: tx_bytes, from: to, amount: amount, contract: contract_address},
      adapter,
      pid
    )
  end

  defp deposit_to_child_chain(to, amount, erc20, contract_address, adapter, pid) do
    tx_bytes =
      []
      |> EthBlockchain.Plasma.Transaction.new([
        {from_hex(to), from_hex(erc20), amount}
      ])
      |> EthBlockchain.Plasma.Transaction.encode()

    EthBlockchain.Transaction.deposit_erc20(
      %{
        tx_bytes: tx_bytes,
        from: to,
        amount: amount,
        root_chain_contract: contract_address,
        erc20_contract: erc20
      },
      adapter,
      pid
    )
  end

  def send(%{
    from: from,
    to: to,
    amount: amount,
    currency: currency_address,
    childchain_identifier: childchain_identifier
  } = attrs,
  adapter \\ nil,
  pid \\ nil) do
    #TODO: extract this in function
    # check that childchain identifier is supported
    childchains = Application.get_env(:eth_blockchain, :childchains)

    childchain_identifier =
      childchain_identifier || Application.get_env(:eth_blockchain, :default_childchain)

    case Map.get(childchains, childchain_identifier) do
      nil ->
        {:error, :childchain_not_supported}

      config ->
        do_send(from, to, amount, currency_address, config, adapter, pid)
    end
  end

  defp do_send(from, to, amount, currency_address, config, adapter, pid) do
    case prepare_transaction(from, to, amount, currency_address, config, adapter, pid) do
      # Handling only complete transactions
      {:ok, %{"result" => "complete", "transactions" => [%{"sign_hash" => sign_hash, "typed_data" => typed_data} | _]}} ->
        sign_hash
        |> sign(from)
        |> submit_typed(typed_data, config)
      {:ok, %{"result" => "intermediate"}} -> {:error, :todo} #TODO Handle intermediate transactions
      {:ok, _} -> {:error, :unhandled}
      error -> error
    end
  end

  defp prepare_transaction(from, to, amount, currency_address, %{watcher_url: watcher_url}, adapter, pid) do
    # TODO: Fee?
    %{
      owner: from,
      payments: [
        %{
          amount: amount,
          currency: currency_address,
          owner: to
        }
      ],
      fee: %{
        amount: 5,
        currency: "0x0000000000000000000000000000000000000000"
      }
    }
    |> Jason.encode!()
    |> EthBlockchain.Plasma.HttpClient.post_request(watcher_url <> "/transaction.create")
  end

  defp sign(sign_hash, from) do
    {:ok, {v, r, s}} = Keychain.Signature.sign_transaction_hash(from_hex(sign_hash), from)
    to_hex(<<r::integer-size(256), s::integer-size(256), v::integer-size(8)>>)
  end

  defp submit_typed(signature, typed_data, %{watcher_url: watcher_url}) do
    typed_data
    |> Map.put_new("signatures", [signature])
    |> Jason.encode!()
    |> EthBlockchain.Plasma.HttpClient.post_request(watcher_url <> "/transaction.submit_typed")
  end

  def get_block do
    # TODO: get block and parse transactions to find relevant ones
    # to be used by a childchain AddressTracker
  end

  def get_exitable_utxos do
    # TODO: Check if childchain is supported
    # TODO: Retrieve exitable utxos from Watcher API
  end

  def exit(
        %{childchain_identifier: childchain_identifier, address: address, utxos: utxos} = attrs,
        adapter \\ nil,
        pid \\ nil
      ) do
    # TODO: 1. Check if childchain is supported
    # TODO: 2. Attempt to exit all given utxos
  end
end
