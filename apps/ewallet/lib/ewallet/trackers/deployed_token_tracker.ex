# Copyright 2018-2019 OMG Network Pte Ltd
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

defmodule Verity.DeployedTokenTracker do
  @moduledoc """
  This module is used to start and receive callbacks for blockchain transactions corresponding to tokens deployed by Verity.
  """
  @behaviour Verity.BlockchainTransactionTrackerBehaviour

  alias Verity.{
    BlockchainHelper,
    BlockchainTransactionTracker,
    TokenGate
  }

  alias VerityDB.Token

  def start_all_pending do
    identifier = BlockchainHelper.rootchain_identifier()
    Enum.map(Token.Blockchain.all_unfinalized_blockchain(identifier), &start/1)
  end

  def start(%{blockchain_transaction: blockchain_transaction}) do
    BlockchainTransactionTracker.start(blockchain_transaction, __MODULE__)
  end

  @impl Verity.BlockchainTransactionTrackerBehaviour
  def on_confirmed(blockchain_transaction) do
    [blockchain_transaction_uuid: blockchain_transaction.uuid]
    |> Token.get_by(preload: :blockchain_transaction)
    |> TokenGate.on_deployed_transaction_confirmed()

    # TODO handle failure
  end
end
