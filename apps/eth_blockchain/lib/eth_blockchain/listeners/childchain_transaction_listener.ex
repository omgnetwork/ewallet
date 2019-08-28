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

defmodule EthBlockchain.ChildchainTransactionListener do
  @moduledoc """
  Handles the transaction receipt logic for childchain transactions.
  """

  alias EthBlockchain.{Block, Childchain}

  def broadcast_payload(tx_hash, node_adapter, node_adapter_pid) do
    case Childchain.get_transaction_receipt(%{tx_hash: tx_hash},
           cc_node_adapter: node_adapter,
           cc_node_adapter_pid: node_adapter_pid
         ) do
      {:ok, :success, %{eth_block: %{number: block_number}, transaction_hash: transaction_hash}} ->
        confirmations_count = Block.get_number() - block_number + 1
        {:confirmations_count, transaction_hash, confirmations_count, block_number}

      {:ok, :not_found} ->
        # Do nothing for now. TODO: increase checking interval until maximum is reached
        # then build a failed_transaction payload?
        {:not_found}

      {:error, error} ->
        {:adapter_error, error}

      {:error, code, _message} ->
        {:adapter_error, code}
    end
  end
end
