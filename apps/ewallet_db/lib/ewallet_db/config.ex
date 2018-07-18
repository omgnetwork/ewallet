defmodule EWalletDB.Config do
  @moduledoc """
  Provides a configuration function that are called during application startup.
  """

  def configure_file_storage do
    storage_adapter = System.get_env("FILE_STORAGE_ADAPTER") || "local"
    configure_file_storage(storage_adapter)
  end

  defp configure_file_storage("aws") do
    aws_bucket = System.get_env("AWS_BUCKET")
    aws_region = System.get_env("AWS_REGION")
    aws_access_key_id = System.get_env("AWS_ACCESS_KEY_ID")
    aws_secret_access_key = System.get_env("AWS_SECRET_ACCESS_KEY")

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

  defp configure_file_storage("gcs") do
    gcs_bucket = System.get_env("GCS_BUCKET")
    gcs_credentials = System.get_env("GCS_CREDENTIALS")

    Application.put_env(:arc, :storage, Arc.Storage.GCS)
    Application.put_env(:arc, :bucket, gcs_bucket)
    Application.put_env(:goth, :json, gcs_credentials)
  end

  defp configure_file_storage("local") do
    Application.put_env(:arc, :storage, EWallet.Storage.Local)
  end
end
