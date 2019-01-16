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

defmodule EWallet.AdapterHelper do
  @moduledoc """
  Helper for everything export-related. This module contains
  streaming functions to load data from the DB and send it
  to a file/remote storage.
  """
  alias EWallet.Exporter
  alias EWalletDB.{Repo, Export, Uploaders}
  alias EWalletConfig.{FileStorageSupervisor, Storage.Local}

  @rows_count 500
  @timeout_milliseconds 1 * 60 * 60 * 1000

  def stream_to_file(path, export, query, serializer, chunk_size) do
    Repo.transaction(
      fn ->
        export
        |> stream_to_chunk(query, serializer, chunk_size)
        |> Stream.into(File.stream!(path, [:write, :utf8]))
        |> Stream.run()
      end,
      timeout: @timeout_milliseconds
    )
  end

  def stream_to_chunk(export, query, serializer, chunk_size) do
    chunk = fn line, {acc, count} ->
      if byte_size(acc) >= chunk_size do
        {:cont, {"#{acc}#{line}", count + 1}, {"", count + 1}}
      else
        {:cont, {"#{acc}#{line}", count + 1}}
      end
    end

    after_chunk = fn {acc, count} ->
      {:cont, {acc, count}, {"", count}}
    end

    query
    |> Repo.stream(max_rows: @rows_count)
    |> Stream.map(fn e -> serializer.serialize(e) end)
    |> CSV.encode(headers: serializer.columns)
    |> Stream.chunk_while({"", 0}, chunk, after_chunk)
    |> Stream.map(fn {chunk, count} ->
      # -1 for header row
      completion =
        case count * 100 / export.total_count - 1 do
          count when count <= 100 -> count
          _ -> 100
        end

      {:ok, _export} =
        update_export(
          export,
          Export.processing(),
          completion
        )

      chunk
    end)
  end

  def setup_local_dir do
    File.mkdir_p(local_dir())
  end

  def local_dir do
    [
      Application.get_env(:ewallet, :root),
      Uploaders.File.storage_dir(nil, nil)
    ]
    |> Path.join()
  end

  def build_local_path(filename) do
    Local.get_path(Uploaders.File.storage_dir(nil, nil), filename)
  end

  def update_export(export, status, completion) do
    Export.update(export, %{
      originator: %Exporter{},
      status: status,
      completion: completion
    })
  end

  def update_export(export, status, completion, pid) do
    Export.update(export, %{
      originator: %Exporter{},
      status: status,
      completion: completion,
      pid: pid
    })
  end

  def store_error(export, error, full_error \\ nil) do
    Export.update(export, %{
      originator: %Exporter{},
      status: Export.failed(),
      failure_reason: error,
      full_error: nil
    })
  end

  def check_adapter_status do
    case Application.get_env(:ewallet, :file_storage_adapter) do
      "gcs" ->
        FileStorageSupervisor
        |> GenServer.call(:status)
        |> handle_adapter_status()

      _ ->
        :ok
    end
  end

  defp handle_adapter_status(:ko), do: {:error, :adapter_server_not_running}
  defp handle_adapter_status(:ok), do: :ok
end
