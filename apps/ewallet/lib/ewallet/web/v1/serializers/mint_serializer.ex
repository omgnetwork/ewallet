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

defmodule EWallet.Web.V1.MintSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator

  alias EWallet.Web.V1.{
    AccountSerializer,
    PaginatorSerializer,
    TokenSerializer,
    TransactionSerializer
  }

  alias Utils.Helpers.{Assoc, DateFormatter}
  alias EWalletDB.Mint

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(mints) when is_list(mints) do
    Enum.map(mints, &serialize/1)
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%Mint{} = mint) do
    %{
      object: "mint",
      id: mint.id,
      description: mint.description,
      amount: mint.amount,
      confirmed: mint.confirmed,
      token_id: Assoc.get(mint, [:token, :id]),
      token: TokenSerializer.serialize(mint.token),
      account_id: Assoc.get(mint, [:account, :id]),
      account: AccountSerializer.serialize(mint.account),
      transaction_id: Assoc.get(mint, [:transaction, :id]),
      transaction: TransactionSerializer.serialize(mint.transaction),
      created_at: DateFormatter.to_iso8601(mint.inserted_at),
      updated_at: DateFormatter.to_iso8601(mint.updated_at)
    }
  end
end
