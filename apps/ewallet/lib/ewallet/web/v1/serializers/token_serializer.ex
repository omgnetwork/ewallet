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

defmodule EWallet.Web.V1.TokenSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.Token
  alias Utils.Helpers.DateFormatter

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(tokens) when is_list(tokens) do
    Enum.map(tokens, &serialize/1)
  end

  def serialize(%Token{} = token) do
    %{
      object: "token",
      id: token.id,
      symbol: token.symbol,
      name: token.name,
      subunit_to_unit: token.subunit_to_unit,
      metadata: token.metadata || %{},
      encrypted_metadata: token.encrypted_metadata || %{},
      enabled: token.enabled,
      created_at: DateFormatter.to_iso8601(token.inserted_at),
      updated_at: DateFormatter.to_iso8601(token.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
