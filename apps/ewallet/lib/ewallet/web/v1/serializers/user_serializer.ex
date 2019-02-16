# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.UserSerializer do
  @moduledoc """
  Serializes user(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Paginator, V1.PaginatorSerializer}
  alias EWalletDB.Uploaders.Avatar
  alias EWalletDB.User
  alias Utils.Helpers.DateFormatter

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(users) when is_list(users) do
    %{
      object: "list",
      data: Enum.map(users, &serialize/1)
    }
  end

  def serialize(%User{} = user) do
    %{
      object: "user",
      id: user.id,
      socket_topic: "user:#{user.id}",
      username: user.username,
      full_name: user.full_name,
      calling_name: user.calling_name,
      provider_user_id: user.provider_user_id,
      email: user.email,
      metadata: user.metadata || %{},
      encrypted_metadata: user.encrypted_metadata || %{},
      avatar: Avatar.urls({user.avatar, user}),
      enabled: user.enabled,
      created_at: DateFormatter.to_iso8601(user.inserted_at),
      updated_at: DateFormatter.to_iso8601(user.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%NotLoaded{}, _), do: nil

  def serialize(users, :id) when is_list(users) do
    Enum.map(users, fn user -> user.id end)
  end

  def serialize(nil, _), do: nil
end
