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

defmodule EWallet.Web.V1.BlockchainTransactionSerializer do
  @moduledoc """
  Serializes blockchain_transaction(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.BlockchainTransaction
  alias Utils.Helpers.DateFormatter

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(blockchain_transactions) when is_list(blockchain_transactions) do
    Enum.map(blockchain_transactions, &serialize/1)
  end

  def serialize(%BlockchainTransaction{} = blockchain_transaction) do
    %{
      object: "blockchain_transaction",
      hash: blockchain_transaction.hash,
      rootchain_identifier: blockchain_transaction.rootchain_identifier,
      childchain_identifier: blockchain_transaction.childchain_identifier,
      status: blockchain_transaction.status,
      block_number: blockchain_transaction.block_number,
      confirmed_at_block_number: blockchain_transaction.confirmed_at_block_number,
      gas_price: blockchain_transaction.gas_price,
      gas_limit: blockchain_transaction.gas_limit,
      error: blockchain_transaction.error,
      metadata: blockchain_transaction.metadata,
      created_at: DateFormatter.to_iso8601(blockchain_transaction.inserted_at),
      updated_at: DateFormatter.to_iso8601(blockchain_transaction.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
