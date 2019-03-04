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

defmodule AdminAPI.V1.TransactionExportControllerTest do
  use AdminAPI.ConnCase
  alias EWalletDB.Uploaders
  alias Utils.Helper.PidHelper
  alias EWalletConfig.Config
  alias ActivityLogger.System

  setup do
    assert Application.get_env(:admin_api, :file_storage_adapter) == "local"
    %{}
  end

  describe "/transaction.export" do
    test_with_auths "generates a csv file" do
      insert_list(100, :transaction)
      assert Application.get_env(:admin_api, :file_storage_adapter) == "local"

      response =
        request("/transaction.export", %{
          "sort_by" => "created",
          "sort_dir" => "desc"
        })

      assert response["success"] == true
      data = response["data"]

      assert data["adapter"] == "local"
      assert data["status"] == "processing"
      assert data["pid"]

      # Wait until the export process shuts down and check that it shutted down normally
      pid = PidHelper.pid_from_string(data["pid"])
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, object, reason} ->
          assert object == pid
          assert reason == :normal
      after
        60_000 ->
          flunk("The export process timed out after 60 seconds")
      end

      response = request("/export.get", %{"id" => data["id"]})
      data = response["data"]

      assert data["completion"] == 100
      assert data["status"] == "completed"

      response = raw_request("/export.download", %{"id" => data["id"]})

      response
      |> CSV.decode()
      |> Stream.each(fn row ->
        assert [
                 ["id", _],
                 ["idempotency_token", _],
                 ["from_user_id", _]
               ] = row
      end)

      {:ok, _} =
        [
          Application.get_env(:ewallet, :root),
          Uploaders.File.storage_dir(nil, nil)
        ]
        |> Path.join()
        |> File.rm_rf()
    end

    test_with_auths "fails to generate a CSV when GCS is not properly configured", context do
      {:ok, _} =
        Config.update(
          %{
            file_storage_adapter: "gcs",
            gcs_bucket: "bucket",
            gcs_credentials: "123",
            originator: %System{}
          },
          context[:config_pid]
        )

      insert_list(1, :transaction)
      assert Application.get_env(:ewallet, :file_storage_adapter) == "gcs"

      response =
        request("/transaction.export", %{
          "sort_by" => "created",
          "sort_dir" => "desc"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "adapter:server_not_running"
    end

    test_with_auths "returns an 'export:no_records' error when there are no records" do
      response =
        request("/transaction.export", %{
          "sort_by" => "created",
          "sort_dir" => "desc"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "export:no_records"
    end
  end
end
