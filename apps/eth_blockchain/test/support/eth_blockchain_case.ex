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

defmodule EthBlockchain.EthBlockchainCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias EthBlockchain.{AdapterServer, Transaction}
  alias Ecto.UUID
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletConfig.ConfigTestHelper
  alias Keychain.Signature
  alias Utils.Helpers.Encoding

  using do
    quote do
      import EthBlockchain.EthBlockchainCase
      alias EthBlockchain.DumbAdapter
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ActivityLogger.Repo)
    :ok = Sandbox.checkout(EWalletConfig.Repo)
    :ok = Sandbox.checkout(Keychain.Repo)

    unless tags[:async] do
      Sandbox.mode(ActivityLogger.Repo, {:shared, self()})
      Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
      Sandbox.mode(Keychain.Repo, {:shared, self()})
    end

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:eth_blockchain],
      %{
        "chain_id" => 0,
        "blockchain_transaction_poll_interval" => 100,
        "blockchain_default_gas_price" => 20_000_000_000
      }
    )

    supervisor = String.to_atom("#{UUID.generate()}")

    {:ok, _} =
      DynamicSupervisor.start_link(
        name: supervisor,
        strategy: :one_for_one
      )

    {:ok, pid} =
      AdapterServer.start_link(
        supervisor: supervisor,
        adapters: [
          {:dumb, EthBlockchain.DumbAdapter},
          {:dumb_tx, EthBlockchain.DumbTxAdapter},
          {:dumb_tx_error, EthBlockchain.DumbTxErrorAdapter},
          {:dumb_cc, EthBlockchain.DumbCCAdapter}
        ]
      )

    %{
      adapter_opts: [
        eth_node_adapter: :dumb,
        eth_node_adapter_pid: pid,
        cc_node_adapter: :dumb_cc,
        cc_node_adapter_pid: pid
      ],
      invalid_adapter_opts: [
        eth_node_adapter: :blah,
        eth_node_adapter_pid: pid
      ],
      supervisor: supervisor,
      addr_0: "0x0000000000000000000000000000000000000000",
      addr_1: "0x0000000000000000000000000000000000000001",
      addr_2: "0x0000000000000000000000000000000000000002",
      addr_3: "0x0000000000000000000000000000000000000003"
    }
  end

  def decode_transaction_response(%{tx_hash: tx_hash}) do
    tx_hash
    |> Encoding.from_hex()
    |> ExRLP.decode()
    |> Transaction.deserialize()
  end

  def recover_public_key(trx) do
    chain_id = Application.get_env(:eth_blockchain, :blockchain_chain_id)

    IO.inspect(chain_id)

    {:ok, pub_key} =
      trx
      |> Transaction.transaction_hash(chain_id)
      |> Signature.recover_public_key(trx.r, trx.s, trx.v, chain_id)

    pub_key
  end
end
