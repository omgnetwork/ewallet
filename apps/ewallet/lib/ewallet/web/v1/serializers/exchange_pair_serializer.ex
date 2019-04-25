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

defmodule EWallet.Web.V1.ExchangePairSerializer do
  @moduledoc """
  Serializes exchange pairs into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.{PaginatorSerializer, TokenSerializer}
  alias EWalletDB.ExchangePair
  alias Utils.Helpers.{Assoc, DateFormatter}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(exchange_pairs) when is_list(exchange_pairs) do
    %{
      object: "list",
      data: Enum.map(exchange_pairs, &serialize/1)
    }
  end

  def serialize(%ExchangePair{} = exchange_pair) do
    exchange_pair = Map.put_new(exchange_pair, :opposite_exchange_pair, nil)

    exchange_pair
    |> serialize_without_opposite_pair()
    |> Map.put(
      :opposite_exchange_pair_id,
      get_opposite_pair_id(exchange_pair.opposite_exchange_pair)
    )
    |> Map.put(
      :opposite_exchange_pair,
      serialize_without_opposite_pair(exchange_pair.opposite_exchange_pair)
    )
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize_without_opposite_pair(%ExchangePair{} = exchange_pair) do
    %{
      object: "exchange_pair",
      id: exchange_pair.id,
      name: ExchangePair.get_name(exchange_pair),
      from_token_id: Assoc.get(exchange_pair, [:from_token, :id]),
      from_token: TokenSerializer.serialize(exchange_pair.from_token),
      to_token_id: Assoc.get(exchange_pair, [:to_token, :id]),
      to_token: TokenSerializer.serialize(exchange_pair.to_token),
      rate: exchange_pair.rate,
      default_exchange_wallet_address: exchange_pair.default_exchange_wallet_address,
      allow_end_user_exchanges: exchange_pair.allow_end_user_exchanges,
      created_at: DateFormatter.to_iso8601(exchange_pair.inserted_at),
      updated_at: DateFormatter.to_iso8601(exchange_pair.updated_at),
      deleted_at: DateFormatter.to_iso8601(exchange_pair.deleted_at)
    }
  end

  def serialize_without_opposite_pair(%NotLoaded{}), do: nil
  def serialize_without_opposite_pair(nil), do: nil

  defp get_opposite_pair_id(nil), do: nil
  defp get_opposite_pair_id(exchange_pair), do: exchange_pair.id
end
