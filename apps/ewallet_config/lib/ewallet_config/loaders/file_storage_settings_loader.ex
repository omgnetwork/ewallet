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
    if Mix.env() != :test do
      Logger.warn(~s([File Storage Configuration]: Setting hasn't been generated.))
    end
  end

  defp load_file_storage("aws", app) do
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
    gcs_bucket = Application.get_env(app, :gcs_bucket)
    gcs_credentials = Application.get_env(app, :gcs_credentials)

    Application.put_env(:arc, :storage, Arc.Storage.GCS)
    Application.put_env(:arc, :bucket, gcs_bucket)
    Application.put_env(:goth, :json, gcs_credentials)
  end

  defp load_file_storage("local", _app) do
    Application.put_env(:arc, :storage, EWalletConfig.Storage.Local)
  end

  defp load_file_storage(storage, _app) do
    Logger.warn(~s([File Storage Configuration]: Unknown option: "#{storage}"))
  end
end
