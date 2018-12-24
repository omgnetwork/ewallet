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

defmodule EWallet.Web.V1.ExportSerializer do
  @moduledoc """
  Serializes exports data into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.PaginatorSerializer
  alias Utils.Helpers.Assoc
  alias EWalletDB.Export

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%Export{} = export) do
    %{
      object: "export",
      id: export.id,
      filename: export.filename,
      schema: export.schema,
      status: export.status,
      completion: export.completion,
      download_url: export.url,
      adapter: export.adapter,
      user_id: Assoc.get(export, [:user, :id]),
      key_id: Assoc.get(export, [:key, :id]),
      params: export.params,
      pid: export.pid,
      created_at: Date.to_iso8601(export.inserted_at),
      updated_at: Date.to_iso8601(export.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
