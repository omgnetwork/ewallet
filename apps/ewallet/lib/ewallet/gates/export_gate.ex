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

defmodule EWallet.ExportGate do
  @moduledoc """
  Handles the logic for creating and saving and export.
  """
  alias EWallet.CSVExporter
  alias EWallet.Exporters.{S3Adapter, GCSAdapter, LocalAdapter}
  alias EWalletDB.{User, Key, Export}

  def generate_url(%{adapter: "aws"} = export) do
    S3Adapter.generate_signed_url(export)
  end

  def generate_url(%{adapter: "gcs"} = export) do
    GCSAdapter.generate_signed_url(export)
  end

  def generate_url(%{adapter: "local"} = export) do
    LocalAdapter.generate_signed_url(export)
  end

  def export(query, schema, serializer, attrs, opts \\ []) do
    preloads = Keyword.get(opts, :preloads, [])

    with {:ok, export} <- insert_export(schema, attrs),
         {:ok, _pid, export} <-
           CSVExporter.start(export, schema, query, serializer, preloads: preloads) do
      {:ok, export}
    else
      error -> error
    end
  end

  defp insert_export(schema, %{originator: %User{} = user} = attrs) do
    attrs
    |> build_attrs(schema, :user_uuid, user)
    |> Export.insert()
  end

  defp insert_export(schema, %{originator: %Key{} = key} = attrs) do
    attrs
    |> build_attrs(schema, :key_uuid, key)
    |> Export.insert()
  end

  defp build_attrs(attrs, schema, owner_key, owner) do
    %{
      schema: schema,
      format: attrs[:export_format] || "csv",
      status: Export.new(),
      completion: 0,
      originator: owner,
      params: Map.delete(attrs, :originator)
    }
    |> Map.put(owner_key, owner.uuid)
  end
end
