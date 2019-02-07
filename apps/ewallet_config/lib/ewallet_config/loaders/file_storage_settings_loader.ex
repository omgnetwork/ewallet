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

defmodule EWalletConfig.FileStorageSettingsLoader do
  @moduledoc """
  Maps the DB settings to the configuration needed for ARC and its dependencies.
  """
  require Logger

  def load(app) do
    app
    |> Application.get_env(:file_storage_adapter)
    |> load_file_storage(app)
  end

  defp load_file_storage(nil, _app) do
    if Application.get_env(:ewallet, :env) != :test do
      Logger.warn(~s([File Storage Configuration]: Setting hasn't been generated.))
    end
  end

  defp load_file_storage("aws", app) do
    cleanup_aws()
    cleanup_gcs()

    aws_bucket = Application.get_env(app, :aws_bucket)
    aws_region = Application.get_env(app, :aws_region)
    aws_access_key_id = Application.get_env(app, :aws_access_key_id)
    aws_secret_access_key = Application.get_env(app, :aws_secret_access_key)
    aws_domain = "s3-#{aws_region}.amazonaws.com"

    Application.put_env(:ex_aws, :access_key_id, [aws_access_key_id, :instance_role])
    Application.put_env(:ex_aws, :secret_access_key, [aws_secret_access_key, :instance_role])
    Application.put_env(:ex_aws, :region, aws_region)

    Application.put_env(:ex_aws, :s3, scheme: "https://", host: aws_domain, region: aws_region)

    Application.put_env(:ex_aws, :debug_requests, true)
    Application.put_env(:ex_aws, :recv_timeout, 60_000)
    Application.put_env(:ex_aws, :hackney, recv_timeout: 60_000, pool: false)
    Application.put_env(:arc, :storage, Arc.Storage.S3)
    Application.put_env(:arc, :bucket, aws_bucket)
    Application.put_env(:arc, :asset_host, "https://#{aws_domain}/#{aws_bucket}")
  end

  defp load_file_storage("gcs", app) do
    cleanup_aws()
    cleanup_gcs()

    gcs_bucket = Application.get_env(app, :gcs_bucket)
    gcs_credentials = Application.get_env(app, :gcs_credentials)

    Application.put_env(:arc, :storage, Arc.Storage.GCS)
    Application.put_env(:arc, :bucket, gcs_bucket)
    Application.put_env(:goth, :json, gcs_credentials)

    _ = GenServer.call(EWalletConfig.FileStorageSupervisor, :stop_goth)
    {:ok, _pid} = GenServer.call(EWalletConfig.FileStorageSupervisor, :start_goth)
  end

  defp load_file_storage("local", _app) do
    cleanup_aws()
    cleanup_gcs()

    Application.put_env(:arc, :storage, EWalletConfig.Storage.Local)
  end

  defp load_file_storage(storage, _app) do
    Logger.warn(~s([File Storage Configuration]: Unknown option: "#{storage}"))
  end

  defp cleanup_gcs do
    _ = GenServer.call(EWalletConfig.FileStorageSupervisor, :stop_goth)
    Application.delete_env(:arc, :storage)
    Application.delete_env(:arc, :bucket)
    Application.delete_env(:goth, :json)
  end

  defp cleanup_aws do
    Application.delete_env(:arc, :asset_host)
    Application.delete_env(:ex_aws, :secret_access_key)
    Application.delete_env(:ex_aws, :region)
    Application.delete_env(:ex_aws, :s3)
    Application.delete_env(:ex_aws, :debug_requests)
    Application.delete_env(:ex_aws, :recv_timeout)
    Application.delete_env(:ex_aws, :hackney)
    Application.delete_env(:arc, :storage)
    Application.delete_env(:arc, :bucket)
    Application.delete_env(:arc, :asset_host)
  end
end
