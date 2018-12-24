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

defmodule EWallet.CSVExporter do
  @moduledoc """
  Entry point for a CSV exporter. Runs a GenServer that will take
  care of the export using the appropriate adapter.
  """
  use GenServer
  import Ecto.Query
  alias EWallet.{S3Adapter, GCSAdapter, LocalAdapter, Exporter}
  alias EWalletDB.{Repo, Export}
  alias Utils.Helper.PidHelper

  def start(export, schema, query, serializer) do
    with count <- get_count(query),
         {:ok, record_estimated_size} <- get_size_estimate(query, serializer),
         estimated_size <- record_estimated_size * count,
         {:ok, export} <- Export.init(export, schema, count, estimated_size, %Exporter{}),
         {:ok, pid} <-
           GenServer.start_link(
             __MODULE__,
             [
               export: export,
               query: query,
               serializer: serializer
             ],
             name: {:global, export.uuid}
           ),
         {:ok, export} <-
           Export.update(export, %{
             pid: PidHelper.pid_to_binary(pid),
             originator: %Exporter{}
           }),
         :ok <- GenServer.cast(pid, :upload) do
      {:ok, pid, export}
    else
      error ->
        error
    end
  end

  def init(export: export, query: query, serializer: serializer) do
    {:ok,
     %{
       query: query,
       serializer: serializer,
       export: export
     }}
  end

  def handle_cast(:upload, state) do
    adapter_module = get_adapter_module()
    adapter_module.upload(state)

    {:noreply, state}
  end

  defp get_adapter_module do
    case Application.get_env(:ewallet, :file_storage_adapter) do
      "aws" -> S3Adapter
      "gcs" -> GCSAdapter
      "local" -> LocalAdapter
    end
  end

  defp get_count(query) do
    Repo.aggregate(query, :count, :uuid)
  end

  defp get_size_estimate(query, serializer) do
    query
    |> limit(10)
    |> Repo.all()
    |> serialize_sample(serializer)
    |> case do
      {:error, _} = error ->
        error

      [_columns | rows] ->
        {:ok, byte_size(Enum.join(rows)) / length(rows)}
    end
  end

  defp serialize_sample(sample_records, serializer) do
    case Enum.empty?(sample_records) do
      true ->
        {:error, :export_no_records}

      false ->
        sample_records
        |> Enum.map(fn r -> serializer.serialize(r) end)
        |> CSV.encode(headers: serializer.columns)
        |> Enum.to_list()
    end
  end
end
