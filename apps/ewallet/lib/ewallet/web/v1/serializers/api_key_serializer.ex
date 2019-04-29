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

defmodule EWallet.Web.V1.APIKeySerializer do
  @moduledoc """
  Serializes API key(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletDB.APIKey
  alias Utils.Helpers.{Assoc, DateFormatter}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%APIKey{} = api_key) do
    %{
      object: "api_key",
      id: api_key.id,
      name: api_key.name,
      key: api_key.key,
      creator_user_id: Assoc.get(api_key, [:creator_user, :id]),
      creator_key_id: Assoc.get(api_key, [:creator_key, :id]),
      enabled: api_key.enabled,
      created_at: DateFormatter.to_iso8601(api_key.inserted_at),
      updated_at: DateFormatter.to_iso8601(api_key.updated_at),
      deleted_at: DateFormatter.to_iso8601(api_key.deleted_at),

      # Attributes below are DEPRECATED and will be removed in the future:
      ## An APIKey is no longer tied to an account since PR #870
      account_id: nil,
      ## An APIKey is no longer tied to an owner_app since PR #870
      owner_app: "ewallet_api",
      ## "expired" has been replaced by "enabled" in PR #535
      expired: !api_key.enabled
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
