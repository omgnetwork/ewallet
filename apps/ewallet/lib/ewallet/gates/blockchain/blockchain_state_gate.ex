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

defmodule EWallet.BlockchainStateGate do
  @moduledoc """
  Handles the retrieval and formatting of addresses for the blockchain
  """

  alias EWalletDB.{BlockchainState, BlockchainTransaction}

  def get_last_synced_blk_number(blockchain_identifier) do
    tx_blk_number = BlockchainTransaction.get_last_block_number(blockchain_identifier)
    state_blk_number = get_state_blk_number(blockchain_identifier)

    get_highest_blk_number(blockchain_identifier, state_blk_number, tx_blk_number)
  end

  defp get_state_blk_number(blockchain_identifier) do
    BlockchainState.get(blockchain_identifier).blk_number
  end

  defp get_highest_blk_number(_blockchain, state_blk_number, nil), do: state_blk_number

  defp get_highest_blk_number(blockchain, state_blk_number, tx_blk_number)
       when is_integer(state_blk_number) and is_integer(tx_blk_number) do
    case state_blk_number > tx_blk_number do
      true ->
        state_blk_number

      false ->
        {:ok, state} = BlockchainState.update(blockchain, tx_blk_number)
        state.blk_number
    end
  end
end
