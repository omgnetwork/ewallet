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

defmodule EWalletDB.ExportTest do
  use EWalletDB.SchemaCase
  import EWalletDB.Factory
  alias EWalletDB.{Export, Repo}
  alias Ecto.UUID
  alias Utils.Helper.PidHelper

  describe "new/0" do
    test "returns the string representation of the 'new' status" do
      assert Export.new() == "new"
    end
  end

  describe "processing/0" do
    test "returns the string representation of the 'processing' status" do
      assert Export.processing() == "processing"
    end
  end

  describe "completed/0" do
    test "returns the string representation of the 'completed' status" do
      assert Export.completed() == "completed"
    end
  end

  describe "failed/0" do
    test "returns the string representation of the 'failed' status" do
      assert Export.failed() == "failed"
    end
  end

  describe "all_for/1" do
    test "returns all exports for the given user" do
      user = insert(:user)
      user_unused = insert(:user)
      key_unused = insert(:key)

      extra_attrs = [
        %{user_uuid: user.uuid},
        %{user_uuid: user_unused.uuid},
        %{user_uuid: user.uuid},
        %{key_uuid: key_unused.uuid},
        %{user_uuid: user.uuid}
      ]

      Enum.each(extra_attrs, fn attrs ->
        :export
        |> params_for(attrs)
        |> Export.insert()
      end)

      exports = user |> Export.all_for("local") |> Repo.all()

      assert Enum.all?(exports, fn e -> e.user_uuid == user.uuid end)
    end

    test "returns all exports for the given key" do
      key = insert(:key)
      key_unused = insert(:key)
      user_unused = insert(:user)

      extra_attrs = [
        %{key_uuid: key.uuid},
        %{key_uuid: key_unused.uuid},
        %{key_uuid: key.uuid},
        %{user_uuid: user_unused.uuid},
        %{key_uuid: key.uuid}
      ]

      Enum.each(extra_attrs, fn attrs ->
        :export
        |> params_for(attrs)
        |> Export.insert()
      end)

      exports = key |> Export.all_for("local") |> Repo.all()

      assert Enum.all?(exports, fn e -> e.key_uuid == key.uuid end)
    end
  end

  describe "get/2" do
    test "returns the export with the given id" do
      {:ok, export} =
        :export
        |> params_for(user_uuid: insert(:user).uuid)
        |> Export.insert()

      retrieved = Export.get(export.id)

      assert retrieved.uuid == export.uuid
    end

    test "returns nil if export with the given id does not exist" do
      assert Export.get("exp_12345678901234567890123456") == nil
    end
  end

  describe "get_by/2" do
    test "returns the export that matches the given attribute" do
      {:ok, export} =
        :export
        |> params_for(schema: "some_schema", user_uuid: insert(:user).uuid)
        |> Export.insert()

      retrieved = Export.get_by(schema: "some_schema")

      assert retrieved.uuid == export.uuid
    end
  end

  describe "init/5" do
    test "updates the given export with initial values" do
      user = insert(:user)

      {:ok, export} =
        :export
        |> params_for(user_uuid: insert(:user).uuid)
        |> Export.insert()

      {res, export} = Export.init(export, "transaction", 10, 1000, user)

      assert res == :ok
      assert export.status == "processing"
      assert export.completion == 1
      assert String.starts_with?(export.path, "private/uploads/test/exports/transaction-")
      assert String.ends_with?(export.path, ".csv")
      assert String.ends_with?(export.filename, ".csv")
      assert export.adapter == nil
      assert export.schema == "transaction"
      assert export.total_count == 10
      assert export.estimated_size == 1000
      assert export.originator != nil
    end
  end

  describe "insert/1" do
    setup do
      user = insert(:user)

      attrs = %{
        schema: "transaction",
        status: Export.new(),
        completion: 0,
        params: %{"sort_by" => "created_at", "sort_dir" => "desc"},
        user_uuid: user.uuid,
        originator: user
      }

      %{attrs: attrs}
    end

    test "returns the inserted export", context do
      {res, export} = Export.insert(context.attrs)

      assert res == :ok
      assert export.schema == context.attrs.schema
      assert export.status == context.attrs.status
      assert export.completion == context.attrs.completion
      assert export.params == context.attrs.params
      assert export.user_uuid == context.attrs.user_uuid
    end

    test "returns error when `:schema` is not present", context do
      attrs = Map.delete(context.attrs, :schema)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [schema: {"can't be blank", [validation: :required]}]
    end

    test "returns error when `:status` is not present", context do
      attrs = Map.delete(context.attrs, :status)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [status: {"can't be blank", [validation: :required]}]
    end

    test "returns error when `:completion` is not present", context do
      attrs = Map.delete(context.attrs, :completion)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [completion: {"can't be blank", [validation: :required]}]
    end

    test "returns error when `:completion` is less than 0", context do
      attrs = Map.put(context.attrs, :completion, -1)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?

      assert changeset.errors == [
               completion:
                 {"must be greater than or equal to %{number}", [validation: :number, number: 0]}
             ]
    end

    test "returns error when `:completion` is greater than 100", context do
      attrs = Map.put(context.attrs, :completion, 101)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?

      assert changeset.errors == [
               completion:
                 {"must be less than or equal to %{number}", [validation: :number, number: 100]}
             ]
    end

    test "returns error when `:params` is not present", context do
      attrs = Map.delete(context.attrs, :params)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [params: {"can't be blank", [validation: :required]}]
    end

    test "returns error when both `:user_uuid` and `:key_uuid` are provided", context do
      attrs = Map.put(context.attrs, :key_uuid, insert(:key).uuid)
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?

      assert changeset.errors == [
               {[:user_uuid, :key_uuid],
                {"only one must be present", [validation: :only_one_required]}}
             ]
    end

    test "returns error when the given `format` is not recognized", context do
      attrs = Map.put(context.attrs, :format, "ppt")
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [format: {"is invalid", [validation: :inclusion]}]
    end

    test "returns error when the given `status` is not recognized", context do
      attrs = Map.put(context.attrs, :status, "foobar")
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [status: {"is invalid", [validation: :inclusion]}]
    end

    test "returns error when the given `user_uuid` is not found", context do
      attrs = Map.put(context.attrs, :user_uuid, UUID.generate())
      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [user: {"does not exist", [constraint: :assoc, constraint_name: "export_user_uuid_fkey"]}]
    end

    test "returns error when the given `key_uuid` is not found", context do
      attrs =
        context.attrs
        |> Map.put(:key_uuid, UUID.generate())
        |> Map.delete(:user_uuid)

      {res, changeset} = Export.insert(attrs)

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [key: {"does not exist", [constraint: :assoc, constraint_name: "export_key_uuid_fkey"]}]
    end
  end

  describe "update/1" do
    setup do
      user = insert(:user)

      {:ok, export} =
        Export.insert(%{
          schema: "transaction",
          status: Export.new(),
          completion: 0,
          params: %{"sort_by" => "created_at", "sort_dir" => "desc"},
          user_uuid: user.uuid,
          originator: user
        })

      %{export: export}
    end

    test "updates the given export with the given attributes", context do
      attrs = %{
        status: Export.processing(),
        completion: 0.7,
        url: "https://example.com/different_export_url",
        path: "/some/path",
        filename: "different_filename.csv",
        adapter: "local",
        schema: "different_schema",
        total_count: 100,
        estimated_size: 1024,
        pid: PidHelper.pid_to_binary(self()),
        originator: insert(:user)
      }

      {res, export} = Export.update(context.export, attrs)

      assert res == :ok
      assert export.status == attrs.status
      assert export.completion == attrs.completion
      assert export.url == attrs.url
      assert export.path == attrs.path
      assert export.filename == attrs.filename
      assert export.adapter == attrs.adapter
      assert export.schema == attrs.schema
      assert export.estimated_size == attrs.estimated_size
      assert export.pid == attrs.pid
    end

    test "returns an invalid changeset when given `status` nil", context do
      {res, changeset} = Export.update(context.export, %{status: nil, originator: insert(:user)})

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [status: {"can't be blank", [validation: :required]}]
    end

    test "returns an invalid changeset when given `completion` nil", context do
      {res, changeset} =
        Export.update(context.export, %{completion: nil, originator: insert(:user)})

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [completion: {"can't be blank", [validation: :required]}]
    end
  end
end
