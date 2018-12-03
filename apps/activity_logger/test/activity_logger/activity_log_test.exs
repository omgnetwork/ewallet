defmodule ActivityLogger.ActivityLogTest do
  use ExUnit.Case
  import ActivityLogger.Factory
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
      ActivityLogger.System => "system",
      ActivityLogger.TestDocument => "test_document",
      ActivityLogger.TestUser => "test_user"
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

      activity_log = ActivityLog.get_initial_activity_log("test_user", user.uuid)

      assert activity_log.originator_type == "test_user"
      assert activity_log.originator_uuid == initial_originator.uuid
      assert activity_log.target_type == "test_user"
      assert activity_log.target_uuid == user.uuid
      assert activity_log.action == "insert"
      assert activity_log.inserted_at != nil
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

      assert activity_log.action == "insert"
      assert activity_log.originator_type == "test_user"
      assert activity_log.originator_uuid == admin.uuid
      assert activity_log.target_type == "test_document"
      assert activity_log.target_uuid == record.uuid

      assert activity_log.target_changes == %{
               "title" => record.title,
               "body" => record.body
             }

      assert activity_log.target_encrypted_changes == %{
               "secret_data" => %{"something" => "cool"}
             }

      assert record |> ActivityLog.all_for_target() |> length() == 1
    end
  end

  describe "ActivityLog.update_record_with_activity_log/2" do
    test "does not insert an activity_log when updating a user with no changes" do
      admin = insert(:test_user)
      {:ok, user} = :test_user |> params_for() |> TestUser.insert()
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

      assert activity_log.action == "update"
      assert activity_log.originator_type == "test_user"
      assert activity_log.originator_uuid == admin.uuid
      assert activity_log.target_type == "test_user"
      assert activity_log.target_uuid == record.uuid

      assert activity_log.target_changes == %{
               "username" => record.username
             }

      assert activity_log.target_encrypted_changes == %{}

      assert user |> ActivityLog.all_for_target() |> length() == 2
    end
  end

  describe "perform/4" do
    test "inserts an activity_log and a user as well as a document" do
      admin = insert(:test_user)
      {res, record} = :test_user |> params_for(%{originator: admin}) |> TestUser.insert()
      activity_log = record |> ActivityLog.all_for_target() |> Enum.at(0)

      assert res == :ok

      assert activity_log.action == "insert"
      assert activity_log.originator_type == "test_user"
      assert activity_log.originator_uuid == admin.uuid
      assert activity_log.target_type == "test_user"
      assert activity_log.target_uuid == record.uuid

      assert record |> ActivityLog.all_for_target() |> length() == 1
    end
  end
end
