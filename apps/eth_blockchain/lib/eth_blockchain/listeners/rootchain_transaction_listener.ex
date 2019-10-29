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

defmodule EthBlockchain.RootchainTransactionListener do
  @moduledoc """
  Handles the transaction receipt logic for rootchain transactions.
  """
  alias EthBlockchain.TransactionReceipt

  def broadcast_payload(tx_hash, node_adapter, node_adapter_pid) do
    case TransactionReceipt.get(%{tx_hash: tx_hash},
           eth_node_adapter: node_adapter,
           eth_node_adapter_pid: node_adapter_pid
         ) do
      {:ok, :success, %{block_number: block_number, transaction_hash: transaction_hash}} ->
        {:confirmations_count, transaction_hash, block_number}

      {:ok, :failed, _} ->
        {:failed_transaction}

      {:ok, :not_found, nil} ->
        # Do nothing for now. TODO: increase checking interval until maximum is reached?
        {:not_found}

      {:error, :adapter_error, message} ->
        {:adapter_error, message}

      {:error, error} ->
        {:adapter_error, error}
    end
  end
end
