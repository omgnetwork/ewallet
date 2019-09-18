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

defmodule EthBlockchain.IntegrationHelpers do
  @moduledoc """
  Helpers used when setting up development environment and test fixtures, related to contracts and ethereum.
  Run against `geth --dev` and similar.
  """
  import Utils.Helpers.Encoding

  alias Keychain.{Key, Wallet}
  alias Ethereumex.HttpClient
  alias EthBlockchain.{ABIEncoder, Contract, WaitFor}

  @one_hundred_eth trunc(:math.pow(10, 18) * 100)

  # about 4 Ethereum blocks on "realistic" networks,
  # use to timeout synchronous operations in demos on testnets
  # NOTE: such timeout works only in dev setting;
  # on mainnet one must track its transactions carefully
  @about_4_blocks_time 60_000

  @passphrase "ThisIsATestnetPassphrase"

  @doc """
  Prepares the developer's environment
  """
  def prepare_env do
    {:ok, chain_id} = HttpClient.request("eth_chainId", [], [])
    Application.put_env(:eth_blockchain, :chain_id, int_from_hex(chain_id))
  end

  def entities do
    %{
      alice: generate_entity(),
      hot_wallet: generate_entity()
    }
  end

  defp generate_entity do
    {:ok, {address, public_key}} = Wallet.generate()
    private_key = Key.private_key_for_wallet_id(address)
    import_account(private_key)
    %{private_key: private_key, address: address, public_key: public_key}
  end

  defp import_account(private_key) do
    {:ok, account_enc} =
      HttpClient.request("personal_importRawKey", [private_key, @passphrase], [])

    {:ok, true} = HttpClient.request("personal_unlockAccount", [account_enc, @passphrase, 0], [])

    account_enc
  end

  def fund_account(addr, amount \\ @one_hundred_eth) do
    {:ok, [default_faucet | _]} = HttpClient.eth_accounts()

    {:ok, _tx} =
      %{from: default_faucet, to: addr, value: to_hex(amount)}
      |> HttpClient.eth_send_transaction()
      |> transact_sync!()

    {:ok, addr}
  end

  def transfer_erc20(%{from: from, to: to, amount: amount, contract_address: contract_address}) do
    {:ok, data} = ABIEncoder.transfer(to, amount)

    {:ok, _tx} =
      %{from: from, to: contract_address, data: to_hex(data)}
      |> HttpClient.eth_send_transaction()
      |> transact_sync!()

    :ok
  end

  def deploy_omg(from, initial_amount \\ @one_hundred_eth) do
    deploy_erc20(%{
      from: from,
      name: "OMGToken",
      symbol: "OMG",
      decimals: 18,
      initial_amount: initial_amount
    })
  end

  def deploy_erc20(%{
        from: from,
        name: name,
        symbol: symbol,
        decimals: decimals,
        initial_amount: initial_amount
      }) do
    {:ok, tx_hash, contract_addr, _contract_uuid} =
      Contract.deploy_erc20(
        %{
          from: from,
          name: name,
          symbol: symbol,
          decimals: decimals,
          initial_amount: initial_amount
        },
        :geth
      )

    {:ok, _tx} = transact_sync!({:ok, tx_hash})
    {:ok, contract_addr}
  end

  def transact_sync!({:ok, txhash} = _transaction_submission_result) do
    {:ok, %{"status" => "0x1"} = result} = WaitFor.eth_receipt(txhash, @about_4_blocks_time)
    {:ok, result |> Map.update!("blockNumber", &int_from_hex(&1))}
  end
end
