defmodule EWalletDB.AuditTest do
  use EWalletDB.SchemaCase
  alias Ecto.{Changeset, Multi}
  alias EWalletConfig.System
  alias EWalletDB.{Audit, Repo, User}

  describe "Audit.get_schema/1" do
    test "gets the schema from a type" do
      assert Audit.get_schema("user") == EWalletDB.User
    end
  end

  describe "Audit.get_type/1" do
    test "gets the type from a schema" do
      assert Audit.get_type(EWalletDB.User) == "user"
    end
  end

  describe "Audit.all_for_target/1" do
    test "returns all audits for a target" do
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()

      {:ok, user} =
        User.update(user, %{
          username: "test_username",
          originator: %System{}
        })

      audits = Audit.all_for_target(user)

      assert length(audits) == 2

      results = Enum.map(audits, fn a -> {a.action, a.originator_type, a.target_type} end)
      assert Enum.member?(results, {"insert", "user", "user"})
      assert Enum.member?(results, {"update", "system", "user"})
    end
  end

  describe "Audit.all_for_target/2" do
    test "returns all audits for a target when given a string" do
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()

      {:ok, user} =
        User.update(user, %{
          username: "test_username",
          originator: %System{}
        })

      audits = Audit.all_for_target("user", user.uuid)

      assert length(audits) == 2

      results = Enum.map(audits, fn a -> {a.action, a.originator_type, a.target_type} end)
      assert Enum.member?(results, {"insert", "user", "user"})
      assert Enum.member?(results, {"update", "system", "user"})
    end

    test "returns all audits for a target when given a module name" do
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, _user} = :user |> params_for() |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()

      {:ok, user} =
        User.update(user, %{
          username: "test_username",
          originator: %System{}
        })

      audits = Audit.all_for_target(User, user.uuid)

      assert length(audits) == 2

      results = Enum.map(audits, fn a -> {a.action, a.originator_type, a.target_type} end)
      assert Enum.member?(results, {"insert", "user", "user"})
      assert Enum.member?(results, {"update", "system", "user"})
    end
  end

  describe "Audit.get_initial_audit/2" do
    test "gets the initial audit for a record" do
      initial_originator = insert(:admin)
      {:ok, user} = :user |> params_for(%{originator: initial_originator}) |> User.insert()

      {:ok, user} =
        User.update(user, %{
          username: "test_username",
          originator: %System{}
        })

      audit = Audit.get_initial_audit("user", user.uuid)

      assert audit.originator_type == "user"
      assert audit.originator_uuid == initial_originator.uuid
      assert audit.target_type == "user"
      assert audit.target_uuid == user.uuid
      assert audit.action == "insert"
      assert audit.inserted_at != nil
    end
  end

  describe "Audit.get_initial_originator/2" do
    test "gets the initial originator for a record" do
      initial_originator = insert(:admin)
      {:ok, user} = :user |> params_for(%{originator: initial_originator}) |> User.insert()

      {:ok, user} =
        User.update(user, %{
          username: "test_username",
          originator: %System{}
        })

      originator = Audit.get_initial_originator(user)

      assert originator.__struct__ == User
      assert originator.uuid == initial_originator.uuid
    end
  end

  describe "Audit.insert_record_with_audit/2" do
    test "inserts an audit and a user with encrypted metadata" do
      admin = insert(:admin)

      params =
        params_for(:user, %{
          encrypted_metadata: %{something: "cool"},
          originator: admin
        })

      changeset = Changeset.change(%User{}, params)
      {res, %{audit: audit, record: record}} = Audit.insert_record_with_audit(changeset)

      assert res == :ok

      assert audit.action == "insert"
      assert audit.originator_type == "user"
      assert audit.originator_uuid == admin.uuid
      assert audit.target_type == "user"
      assert audit.target_uuid == record.uuid

      changes =
        changeset.changes
        |> Map.delete(:originator)
        |> Map.delete(:encrypted_metadata)

      assert audit.target_changes == changes
      assert audit.target_encrypted_metadata == %{something: "cool"}

      assert record |> Audit.all_for_target() |> length() == 1
    end

    test "inserts an audit and a user as well as a wallet" do
      admin = insert(:admin)

      params =
        params_for(:user, %{
          encrypted_metadata: %{something: "cool"},
          originator: admin
        })

      changeset = Changeset.change(%User{}, params)

      multi =
        Multi.new()
        |> Multi.run(:wow_user, fn %{record: _record} ->
          {:ok, insert(:user, username: "test_username")}
        end)

      {res, %{audit: audit, record: record, wow_user: wow_user}} =
        Audit.insert_record_with_audit(changeset, multi)

      assert res == :ok

      assert audit.action == "insert"
      assert audit.originator_type == "user"
      assert audit.originator_uuid == admin.uuid
      assert audit.target_type == "user"
      assert audit.target_uuid == record.uuid

      assert wow_user != nil
      assert wow_user.username == "test_username"

      assert record |> Audit.all_for_target() |> length() == 1
    end
  end

  describe "Audit.update_record_with_audit/2" do
    test "inserts an audit when updating a user" do
      admin = insert(:admin)
      {:ok, user} = :user |> params_for() |> User.insert()

      params =
        params_for(:user, %{
          username: "test_username",
          originator: admin
        })

      changeset = Changeset.change(user, params)
      {res, %{audit: audit, record: record}} = Audit.update_record_with_audit(changeset)

      assert res == :ok

      assert audit.action == "update"
      assert audit.originator_type == "user"
      assert audit.originator_uuid == admin.uuid
      assert audit.target_type == "user"
      assert audit.target_uuid == record.uuid
      changes = Map.delete(changeset.changes, :originator)
      assert audit.target_changes == changes

      assert user |> Audit.all_for_target() |> length() == 2
    end

    test "inserts an audit and updates a user as well as saving a wallet" do
      admin = insert(:admin)
      {:ok, user} = :user |> params_for() |> User.insert()

      params =
        params_for(:user, %{
          username: "test_username",
          originator: admin
        })

      changeset = Changeset.change(user, params)

      multi =
        Multi.new()
        |> Multi.run(:wow_user, fn %{record: _record} ->
          {:ok, insert(:user, username: "test_another_username")}
        end)

      {res, %{audit: audit, record: record, wow_user: _}} =
        Audit.update_record_with_audit(changeset, multi)

      assert res == :ok

      assert audit.action == "update"
      assert audit.originator_type == "user"
      assert audit.originator_uuid == admin.uuid
      assert audit.target_type == "user"
      assert audit.target_uuid == record.uuid
      changes = Map.delete(changeset.changes, :originator)
      assert audit.target_changes == changes

      assert user |> Audit.all_for_target() |> length() == 2
    end
  end
end
