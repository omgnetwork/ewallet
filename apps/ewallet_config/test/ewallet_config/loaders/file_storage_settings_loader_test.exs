defmodule EWalletConfig.FileStorageSettingsLoaderTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{ConfigTestHelper, FileStorageSettingsLoader}

  def init(opts) do
    Application.put_env(:my_app, :settings, [
      :file_storage_adapter,
      :aws_bucket,
      :aws_region,
      :aws_access_key_id,
      :aws_secret_access_key,
      :gcs_bucket,
      :gcs_credentials
    ])

    ConfigTestHelper.restart_config_genserver(
      self(),
      EWalletConfig.Repo,
      [:my_app],
      opts
    )

    FileStorageSettingsLoader.load(:my_app)
  end

  describe "load/1" do
    test "load local storage env" do
      init(%{
        "file_storage_adapter" => "local"
      })

      assert Application.get_env(:arc, :storage) == EWalletConfig.Storage.Local
    end

    test "load aws storage env" do
      init(%{
        "file_storage_adapter" => "aws",
        "aws_bucket" => "bucket",
        "aws_region" => "azeroth",
        "aws_access_key_id" => "123",
        "aws_secret_access_key" => "456"
      })

      assert Application.get_env(:arc, :storage) == Arc.Storage.S3

      assert Application.get_env(:ex_aws, :access_key_id, ["123", :instance_role])
      assert Application.get_env(:ex_aws, :secret_access_key, ["456", :instance_role])
      assert Application.get_env(:ex_aws, :region, "azeroth")

      assert Application.get_env(
               :ex_aws,
               :s3,
               scheme: "https://",
               host: "s3-azeroth.amazonaws.com",
               region: "azeroth"
             )

      assert Application.get_env(:ex_aws, :debug_requests, true)
      assert Application.get_env(:ex_aws, :recv_timeout, 60_000)
      assert Application.get_env(:ex_aws, :hackney, recv_timeout: 60_000, pool: false)
      assert Application.get_env(:arc, :bucket, "bucket")
      assert Application.get_env(:arc, :asset_host, "https://s3-azeroth.amazonaws.com/#bucket")
    end

    test "load gcs storage env" do
      init(%{
        "file_storage_adapter" => "gcs",
        "gcs_bucket" => "bucket",
        "gcs_credentials" => "123"
      })

      assert Application.get_env(:arc, :storage) == Arc.Storage.GCS
      assert Application.get_env(:arc, :bucket) == "bucket"
      assert Application.get_env(:goth, :json) == "123"
    end
  end
end
