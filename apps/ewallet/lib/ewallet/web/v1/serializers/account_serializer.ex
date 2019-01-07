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

defmodule EWallet.Web.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.{CategorySerializer, PaginatorSerializer}
  alias EWalletDB.Account
  alias Utils.Helpers.{Assoc, DateFormatter}
  alias EWalletDB.Uploaders.Avatar

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(accounts) when is_list(accounts) do
    %{
      object: "list",
      data: Enum.map(accounts, &serialize/1)
    }
  end

  def serialize(%Account{} = account) do
    %{
      object: "account",
      id: account.id,
      socket_topic: "account:#{account.id}",
      parent_id: Assoc.get(account, [:parent, :id]),
      name: account.name,
      description: account.description,
      master: Account.master?(account),
      category_ids: CategorySerializer.serialize(account.categories, :id),
      categories: CategorySerializer.serialize(account.categories),
      avatar: Avatar.urls({account.avatar, account}),
      metadata: account.metadata || %{},
      encrypted_metadata: account.encrypted_metadata || %{},
      created_at: DateFormatter.to_iso8601(account.inserted_at),
      updated_at: DateFormatter.to_iso8601(account.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%NotLoaded{}, _), do: nil

  def serialize(accounts, :id) when is_list(accounts) do
    Enum.map(accounts, fn account -> account.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil
end
