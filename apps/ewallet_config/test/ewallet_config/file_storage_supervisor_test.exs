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

defmodule EWalletConfig.FileStorageSupervisorTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{ConfigTestHelper, FileStorageSupervisor, FileStorageSettingsLoader}

  def init do
    config = %{
      "file_storage_adapter" => "gcs",
      "gcs_bucket" => "bucket",
      "gcs_credentials" => ~s({
        "type": "service_account",
        "project_id": "ewallet",
        "private_key_id": "private_key_id",
        "private_key": "private_key",
        "client_email": "email@example.com",
        "client_id": "123",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/google-cloud-storage-test-acco%40omise-go.iam.gserviceaccount.com"
      })
    }

    Application.put_env(:my_app, :settings, [
      :file_storage_adapter,
      :gcs_bucket,
      :gcs_credentials
    ])

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:my_app],
      config
    )

    FileStorageSettingsLoader.load(:my_app)
  end

  describe "start_link/0" do
    test "stops and starts a new Supervisor" do
      :ok = FileStorageSupervisor.stop()
      {res, pid} = FileStorageSupervisor.start_link()

      assert res == :ok
      assert pid != nil
    end
  end

  describe "handle_call/3 with :start_goth" do
    test "does nothing if the server is already running" do
      init()
      FileStorageSupervisor.start_link()

      {:ok, pid_1} = GenServer.call(FileStorageSupervisor, :start_goth)
      {res, pid_2} = GenServer.call(FileStorageSupervisor, :start_goth)

      assert res == :ok
      assert pid_2 != nil
      assert pid_1 == pid_2
    end

    test "starts the server if not running" do
      init()
      FileStorageSupervisor.start_link()

      {res, pid} = GenServer.call(FileStorageSupervisor, :start_goth)

      assert res == :ok
      assert pid != nil
    end
  end

  describe "handle_call/3 with :stop_goth" do
    test "does nothing if the server is not running" do
      init()
      FileStorageSupervisor.start_link()

      res = GenServer.call(FileStorageSupervisor, :stop_goth)

      assert res == :ok
    end

    test "stops the server if running" do
      init()

      FileStorageSupervisor.start_link()

      {:ok, pid} = GenServer.call(FileStorageSupervisor, :start_goth)
      assert pid != nil

      res = GenServer.call(FileStorageSupervisor, :stop_goth)

      assert res == :ok
    end
  end
end
