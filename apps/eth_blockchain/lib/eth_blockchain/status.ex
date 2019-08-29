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

defmodule EthBlockchain.Status do
  @moduledoc """
  Provides Ethereum blockchain connection status.
  """
  require Logger
  alias EthBlockchain.{Block, Client}

  @opaque t() :: %{
            eth_syncing: boolean(),
            client_version: String.t(),
            network_id: String.t(),
            peer_count: non_neg_integer(),
            last_seen_eth_block_number: non_neg_integer()
          }

  @doc """
  Returns the status of Ethereum blockchain connectivity.
  """
  @spec get_status() :: {:ok, t()}
  def get_status do
    status = %{
      eth_syncing: Client.get_eth_syncing() |> data_or_nil(),
      client_version: Client.get_client_version() |> data_or_nil(),
      network_id: Client.get_network_id() |> data_or_nil(),
      peer_count: Client.get_peer_count() |> data_or_nil(),
      last_seen_eth_block_number: Block.get_number() |> data_or_nil()
    }

    {:ok, status}
  end

  defp data_or_nil({:error, _, _}), do: nil
  defp data_or_nil({:ok, data}), do: data
end
