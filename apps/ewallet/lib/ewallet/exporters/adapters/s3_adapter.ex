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

defmodule EWallet.Exporters.S3Adapter do
  @moduledoc """
  Export Adapter for Amazon S3.
  """
  alias EWallet.AdapterHelper
  alias EWalletDB.{Repo, Export, Uploaders}
  alias ExAws.S3

  @min_byte_size 5_243_000
  @timeout_milliseconds 1 * 60 * 60 * 1000

  def generate_signed_url(export) do
    {:ok, Uploaders.File.url({export.filename, nil}, :original, signed: true)}
  end

  def upload(args) do
    case args.export.estimated_size > @min_byte_size * 2 do
      true ->
        stream_upload(args)

      false ->
        direct_upload(args)
    end
  end

  defp stream_upload(args) do
    parts = trunc(args.export.estimated_size / @min_byte_size)
    chunk_size = args.export.estimated_size / parts

    Repo.transaction(
      fn ->
        args.export
        |> AdapterHelper.stream_to_chunk(args.query, args.preloads, args.serializer, chunk_size)
        |> S3.upload(get_bucket(), args.path)
        |> ExAws.request()
        |> case do
          {:ok, _} ->
            AdapterHelper.update_export(args.export, Export.completed(), 100, nil)

          {:error, error} ->
            {:ok, export} = AdapterHelper.store_error(args.export, error)
            {:error, export}
        end
      end,
      timeout: @timeout_milliseconds
    )
  end

  defp direct_upload(args) do
    {:ok, data} = to_full_csv(args.query, args.preloads, args.serializer)

    # direct upload
    %{
      filename: args.export.filename,
      binary: data
    }
    |> Uploaders.File.store()
    |> case do
      {:ok, _filename} ->
        AdapterHelper.update_export(args.export, Export.completed(), 100, nil)

      {:error, error} ->
        {:ok, export} = AdapterHelper.store_error(args.export, "Upload failed.", inspect(error))
        {:error, export}
    end
  rescue
    error ->
      {:ok, export} = AdapterHelper.store_error(args.export, "Upload failed.", inspect(error))
      {:error, export}
  end

  defp get_bucket do
    Application.get_env(:ewallet, :aws_bucket)
  end

  defp to_full_csv(query, preloads, serializer) do
    Repo.transaction(fn ->
      query
      |> Repo.stream(max_rows: 500)
      |> Stream.map(fn record ->
        record
        |> Repo.preload(preloads)
        |> serializer.serialize()
      end)
      |> CSV.encode(headers: serializer.columns)
      |> Enum.join("")
    end)
  end
end
