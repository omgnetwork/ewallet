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

defmodule EWallet.Web.V1.BlockchainWalletSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias EWallet.Web.Paginator
  alias Ecto.Association.NotLoaded

  alias EWallet.Web.V1.{ListSerializer, PaginatorSerializer}

  alias EWalletDB.BlockchainWallet
  alias Utils.Helpers.DateFormatter

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(wallets) when is_list(wallets) do
    wallets
    |> Enum.map(&serialize/1)
    |> ListSerializer.serialize()
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%BlockchainWallet{} = wallet) do
    %{
      object: "blockchain_wallet",
      address: wallet.address,
      name: wallet.name,
      type: wallet.type,
      created_at: DateFormatter.to_iso8601(wallet.inserted_at),
      updated_at: DateFormatter.to_iso8601(wallet.updated_at)
    }
  end
end
