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

defmodule EWallet.Web.V1.MembershipSerializer do
  @moduledoc """
  Serializes membership(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator

  alias EWallet.Web.V1.{
    AccountSerializer,
    PaginatorSerializer,
    AdminUserSerializer,
    KeySerializer
  }

  alias Utils.Helpers.{Assoc, DateFormatter}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(memberships) when is_list(memberships) do
    %{
      object: "list",
      data: Enum.map(memberships, &serialize/1)
    }
  end

  def serialize(%NotLoaded{}), do: nil

  def serialize(membership) when is_map(membership) do
    %{
      object: "membership",
      user_id: Assoc.get(membership, [:user, :id]),
      user: AdminUserSerializer.serialize(membership.user),
      key_id: Assoc.get(membership, [:key, :id]),
      key: KeySerializer.serialize(membership.key),
      account_id: Assoc.get(membership, [:account, :id]),
      account: AccountSerializer.serialize(membership.account),
      role: Assoc.get(membership, [:role, :name]),
      created_at: DateFormatter.to_iso8601(membership.inserted_at),
      updated_at: DateFormatter.to_iso8601(membership.updated_at)
    }
  end

  def serialize(nil), do: nil
end
