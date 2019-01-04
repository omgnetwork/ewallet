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

defmodule ActivityLogger.ActivityRepoTest do
  use ExUnit.Case
  use ActivityLogger.ActivityLogging
  import ActivityLogger.Factory
  alias ActivityLogger.{ActivityLog, TestDocument}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset

  defmodule TestRepo do
    use ActivityLogger.ActivityRepo, repo: ActivityLogger.Repo
  end

  setup do
    :ok = Sandbox.checkout(ActivityLogger.Repo)

    ActivityLogger.configure(%{
      ActivityLogger.System => %{type: "system", identifier: nil},
      ActivityLogger.TestDocument => %{type: "test_document", identifier: :id},
      ActivityLogger.TestUser => %{type: "test_user", identifier: :id}
    })

    attrs = %{
      title: "A title",
      body: "some body that we don't want to save",
      secret_data: %{something: "secret"},
      originator: insert(:test_user)
    }

    %{attrs: attrs}
  end

  describe "insert_record_with_activity_log/3" do
    test "inserts the record and the activity log", meta do
      changeset = Changeset.cast(%TestDocument{}, meta.attrs, [:title, :originator])

      # Test for the inserted record
      {res, record} = TestRepo.insert_record_with_activity_log(changeset)

      assert res == :ok
      assert %TestDocument{} = record
      assert record.title == meta.attrs.title

      # Test for the inserted activity log
      activity_logs = ActivityLog.all_for_target(TestDocument, record.uuid)

      assert length(activity_logs) == 1

      assert Enum.any?(activity_logs, fn a ->
               a.action == "insert" && a.originator_uuid == meta.attrs.originator.uuid
             end)
    end
  end

  describe "update_record_with_activity_log/3" do
    test "updates the record and inserts the activity log", meta do
      {:ok, document} = :test_document |> params_for() |> TestDocument.insert()
      changeset = Changeset.cast(document, meta.attrs, [:title, :originator])

      # Test for the updated record
      {res, record} = TestRepo.update_record_with_activity_log(changeset)

      assert res == :ok
      assert record.title == meta.attrs.title

      # Test for the inserted activity log
      activity_logs = ActivityLog.all_for_target(TestDocument, record.uuid)

      assert length(activity_logs) == 2

      assert Enum.any?(activity_logs, fn a ->
               a.action == "insert" && a.originator_type == "system"
             end)

      assert Enum.any?(activity_logs, fn a ->
               a.action == "update" && a.originator_uuid == meta.attrs.originator.uuid
             end)
    end
  end

  describe "delete_record_with_activity_log/3" do
    test "deletes the record and inserts the activity log", meta do
      {:ok, document} = :test_document |> params_for() |> TestDocument.insert()
      changeset = Changeset.cast(document, meta.attrs, [:originator])

      # Test for the deleted record
      {res, record} = TestRepo.delete_record_with_activity_log(changeset)

      assert res == :ok

      # Test for the deleted activity log
      activity_logs = ActivityLog.all_for_target(TestDocument, record.uuid)

      assert length(activity_logs) == 2

      assert Enum.any?(activity_logs, fn a ->
               a.action == "insert" && a.originator_type == "system"
             end)

      assert Enum.any?(activity_logs, fn a ->
               a.action == "delete" && a.originator_uuid == meta.attrs.originator.uuid
             end)
    end
  end
end
