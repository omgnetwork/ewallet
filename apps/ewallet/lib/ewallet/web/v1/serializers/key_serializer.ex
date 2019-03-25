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

defmodule EWallet.Web.V1.KeySerializer do
  @moduledoc """
  Serializes key(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.Key
  alias Utils.Helpers.DateFormatter

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%Key{} = key) do
    %{
      object: "key",
      id: key.id,
      name: key.name,
      access_key: key.access_key,
      secret_key: key.secret_key,
      # Deprecated
      account_id: nil,
      global_role: key.global_role,
      enabled: key.enabled,
      created_at: DateFormatter.to_iso8601(key.inserted_at),
      updated_at: DateFormatter.to_iso8601(key.updated_at),
      deleted_at: DateFormatter.to_iso8601(key.deleted_at),
      # Attributes below are DEPRECATED and will be removed in the future:
      # "expired" has been replaced by "enabled" in PR #535
      expired: !key.enabled
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
