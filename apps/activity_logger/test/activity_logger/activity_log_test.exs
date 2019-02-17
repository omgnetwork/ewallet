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

defmodule ActivityLogger.ActivityLogTest do
  use ExUnit.Case
  use ActivityLogger.ActivityLogging
  import ActivityLogger.Factory
  import ActivityLogger.ActivityLoggerTestHelper
  alias Ecto.Adapters.SQL.Sandbox

  alias ActivityLogger.{
    System,
    ActivityLog,
    TestDocument,
    TestUser
  }

  setup do
    :ok = Sandbox.checkout(ActivityLogger.Repo)

    ActivityLogger.configure(%{
      ActivityLogger.System => %{type: "system", identifier: nil},
      ActivityLogger.TestDocument => %{type: "test_document", identifier: :id},
      ActivityLogger.TestUser => %{type: "test_user", identifier: :id}
    })
  end

  describe "ActivityLog.get_schema/1" do
    test "gets the schema from a type" do
      assert ActivityLog.get_schema("system") == System
    end
  end

  describe "ActivityLog.get_type/1" do
    test "gets the type from a schema" do
      assert ActivityLog.get_type(ActivityLogger.System) == "system"
    end
  end

  describe "ActivityLog.all_for_target/1" do
    test "returns all activity_logs for a target" do
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, user} = :test_user |> params_for() |> TestUser.insert()

      {:ok, user} =
        TestUser.update(user, %{
          username: "Johnny",
          originator: %System{}
        })

      activity_logs = ActivityLog.all_for_target(user)

      assert length(activity_logs) == 2

      results = Enum.map(activity_logs, fn a -> {a.action, a.originator_type, a.target_type} end)

      assert Enum.member?(results, {"insert", "system", "test_user"})
      assert Enum.member?(results, {"update", "system", "test_user"})
    end
  end

  describe "ActivityLog.all_for_target/2" do
    test "returns all activity_logs for a target when given a string" do
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, user} = :test_user |> params_for() |> TestUser.insert()

      {:ok, user} =
        TestUser.update(user, %{
          username: "Johnny",
          originator: %System{}
        })

      activity_logs = ActivityLog.all_for_target("test_user", user.uuid)

      assert length(activity_logs) == 2

      results = Enum.map(activity_logs, fn a -> {a.action, a.originator_type, a.target_type} end)
      assert Enum.member?(results, {"insert", "system", "test_user"})
      assert Enum.member?(results, {"update", "system", "test_user"})
    end

    test "returns all activity_logs for a target when given a module name" do
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, _user} = :test_user |> params_for() |> TestUser.insert()
      {:ok, user} = :test_user |> params_for() |> TestUser.insert()

      {:ok, user} =
        TestUser.update(user, %{
          username: "Johnny",
          originator: %System{}
        })

      activity_logs = ActivityLog.all_for_target(TestUser, user.uuid)

      assert length(activity_logs) == 2

      results = Enum.map(activity_logs, fn a -> {a.action, a.originator_type, a.target_type} end)
      assert Enum.member?(results, {"insert", "system", "test_user"})
      assert Enum.member?(results, {"update", "system", "test_user"})
    end
  end

  describe "ActivityLog.get_initial_activity_log/2" do
    test "gets the initial activity_log for a record" do
      initial_originator = insert(:test_user)

      {:ok, user} =
        :test_user |> params_for(%{originator: initial_originator}) |> TestUser.insert()

      {:ok, user} =
        TestUser.update(user, %{
          username: "Johnny",
          originator: %System{}
        })

      ActivityLog.get_initial_activity_log("test_user", user.uuid)
      |> assert_activity_log(
        action: "insert",
        originator: initial_originator,
        target: user
      )
    end
  end

  describe "ActivityLog.get_initial_originator/2" do
    test "gets the initial originator for a record" do
      initial_originator = insert(:test_user)

      {:ok, user} =
        :test_user |> params_for(%{originator: initial_originator}) |> TestUser.insert()

      {:ok, user} =
        TestUser.update(user, %{
          username: "Johnny",
          originator: %System{}
        })

      originator = ActivityLog.get_initial_originator(user)

      assert originator.__struct__ == TestUser
      assert originator.uuid == initial_originator.uuid
    end
  end

  describe "ActivityLog.insert/3" do
    setup do
      admin = insert(:test_user)

      attrs = %{
        title: "A title",
        body: "some body that we don't want to save",
        secret_data: %{something: "cool"},
        originator: admin
      }

      record = insert(:test_document, attrs)

      %{attrs: attrs, record: record}
    end

    test "inserts everything in target_changes by default", meta do
      changeset =
        %TestDocument{}
        |> cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title, :body, :secret_data],
          required: [:title]
        )

      {:ok, activity_log} = ActivityLog.insert(:insert, changeset, meta.record)

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: meta.attrs.originator,
        target: meta.record,
        changes: %{
          title: meta.attrs.title,
          body: meta.attrs.body,
          secret_data: %{something: "cool"}
        },
        encrypted_changes: %{}
      )
    end

    test "inserts encrypted fields in encrypted_changes", meta do
      changeset =
        %TestDocument{}
        |> cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title, :body, :secret_data],
          required: [:title],
          encrypted: [:secret_data]
        )

      {:ok, activity_log} = ActivityLog.insert(:insert, changeset, meta.record)

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: meta.attrs.originator,
        target: meta.record,
        changes: %{
          title: meta.attrs.title,
          body: meta.attrs.body
        },
        encrypted_changes: %{
          secret_data: meta.attrs.secret_data
        }
      )
    end

    test "does not insert fields protected with `prevent_saving`", meta do
      changeset =
        %TestDocument{}
        |> cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title, :body, :secret_data],
          required: [:title],
          prevent_saving: [:body]
        )

      {:ok, activity_log} = ActivityLog.insert(:insert, changeset, meta.record)

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: meta.attrs.originator,
        target: meta.record,
        changes: %{
          title: meta.attrs.title,
          secret_data: meta.attrs.secret_data
        },
        encrypted_changes: %{}
      )
    end

    test "inserts encrypted_changes, but does not insert fields protected with `prevent_saving`",
         meta do
      changeset =
        %TestDocument{}
        |> cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: [:title, :body, :secret_data],
          required: [:title],
          prevent_saving: [:body],
          encrypted: [:secret_data]
        )

      {:ok, activity_log} = ActivityLog.insert(:insert, changeset, meta.record)

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: meta.attrs.originator,
        target: meta.record,
        changes: %{
          title: meta.attrs.title
        },
        encrypted_changes: %{
          secret_data: meta.attrs.secret_data
        }
      )
    end

    test "does not insert an activity log when there are no changes", meta do
      changeset =
        %TestDocument{}
        |> cast_and_validate_required_for_activity_log(
          meta.attrs,
          cast: []
        )

      {res, activity_log} = ActivityLog.insert(:insert, changeset, meta.record)

      assert res == :ok
      assert activity_log == nil
    end
  end

  describe "ActivityLog.insert_record_with_activity_log/2" do
    test "inserts an activity_log and a document with encrypted metadata" do
      admin = insert(:test_user)

      {res, record} =
        :test_document
        |> params_for(%{
          secret_data: %{something: "cool"},
          originator: admin
        })
        |> TestDocument.insert()

      activity_log = record |> ActivityLog.all_for_target() |> Enum.at(0)

      assert res == :ok

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: admin,
        target: record,
        changes: %{
          "title" => record.title
        },
        encrypted_changes: %{
          "secret_data" => %{"something" => "cool"}
        }
      )

      assert record |> ActivityLog.all_for_target() |> length() == 1
    end
  end

  describe "ActivityLog.update_record_with_activity_log/2" do
    test "does not insert an activity_log when updating a user with no changes" do
      admin = insert(:test_user)
      {:ok, user} = :test_user |> params_for(username: "John") |> TestUser.insert()
      params = params_for(:test_user, %{username: "John", originator: admin})
      {res, _record} = TestUser.update(user, params)

      assert res == :ok
      assert user |> ActivityLog.all_for_target() |> length() == 1
    end

    test "inserts an activity_log when updating a user" do
      admin = insert(:test_user)
      {:ok, user} = :test_user |> params_for() |> TestUser.insert()
      params = params_for(:test_user, %{username: "Johnny", originator: admin})
      {res, record} = TestUser.update(user, params)
      activity_log = record |> ActivityLog.all_for_target() |> Enum.at(0)

      assert res == :ok

      assert_activity_log(
        activity_log,
        action: "update",
        originator: admin,
        target: record,
        changes: %{
          "username" => record.username
        },
        encrypted_changes: %{}
      )

      assert user |> ActivityLog.all_for_target() |> length() == 2
    end
  end

  describe "perform/4" do
    test "inserts an activity_log and a user as well as a document" do
      admin = insert(:test_user)
      {res, record} = :test_user |> params_for(%{originator: admin}) |> TestUser.insert()
      activity_log = record |> ActivityLog.all_for_target() |> Enum.at(0)

      assert res == :ok

      assert_activity_log(
        activity_log,
        action: "insert",
        originator: admin,
        target: record
      )

      assert record |> ActivityLog.all_for_target() |> length() == 1
    end
  end
end
