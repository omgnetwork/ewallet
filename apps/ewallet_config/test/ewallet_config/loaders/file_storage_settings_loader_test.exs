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

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
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
