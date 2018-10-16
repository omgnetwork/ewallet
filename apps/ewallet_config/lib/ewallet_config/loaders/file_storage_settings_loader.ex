defmodule EWalletConfig.FileStorageSettingsLoader do
  alias EWalletConfig.Setting

  def load(_app) do
    "file_storage_adapter"
    |> Setting.get_value()
    |> load_file_storage()
  end

  defp load_file_storage("aws") do
    aws_bucket = Setting.get_value("aws_bucket")
    aws_region = Setting.get_value("aws_region")
    aws_access_key_id = Setting.get_value("aws_access_key_id")
    aws_secret_access_key = Setting.get_value("aws_secret_access_key")
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

  defp load_file_storage("gcs") do
    gcs_bucket = Setting.get_value("gcs_bucket")
    gcs_credentials = Setting.get_value("gcs_credentials")

    Application.put_env(:arc, :storage, Arc.Storage.GCS)
    Application.put_env(:arc, :bucket, gcs_bucket)
    Application.put_env(:goth, :json, gcs_credentials)
  end

  defp load_file_storage("local") do
    Application.put_env(:arc, :storage, EWalletConfig.Storage.Local)
  end
end
