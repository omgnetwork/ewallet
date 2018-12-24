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

defmodule EWallet.Web.V1.CategorySerializer do
  @moduledoc """
  Serializes categories into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{AccountSerializer, PaginatorSerializer}
  alias EWalletDB.Category

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(categories) when is_list(categories) do
    %{
      object: "list",
      data: Enum.map(categories, &serialize/1)
    }
  end

  def serialize(%Category{} = category) do
    %{
      object: "category",
      id: category.id,
      name: category.name,
      description: category.description,
      account_ids: AccountSerializer.serialize(category.accounts, :id),
      accounts: AccountSerializer.serialize(category.accounts),
      created_at: Date.to_iso8601(category.inserted_at),
      updated_at: Date.to_iso8601(category.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(categories, :id) when is_list(categories) do
    Enum.map(categories, fn category -> category.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil
end
