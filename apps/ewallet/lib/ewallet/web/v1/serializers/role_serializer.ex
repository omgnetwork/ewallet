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

defmodule EWallet.Web.V1.RoleSerializer do
  @moduledoc """
  Serializes roles into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.Role

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(roles) when is_list(roles) do
    %{
      object: "list",
      data: Enum.map(roles, &serialize/1)
    }
  end

  def serialize(%Role{} = role) do
    %{
      object: "role",
      id: role.id,
      name: role.name,
      priority: role.priority,
      display_name: role.display_name,
      created_at: Date.to_iso8601(role.inserted_at),
      updated_at: Date.to_iso8601(role.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(roles, :id) when is_list(roles) do
    Enum.map(roles, fn role -> role.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil
end
