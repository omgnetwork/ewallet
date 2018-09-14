defmodule EWalletDB.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for EWalletDB schema tests.

  Note that all macros below are quoted at `test ... do ... end` level
  with macro names starting with `test_`. This is so that in test cases,
  when these macros are used, they still resemble the original code.

  ## Example

  ### Original code:

  ```
  describe "SomeSchema.insert/1" do
    test "generates a UUID for SomeSchema" do
      # ...
      # lots of test code here
      # ...
    end

    test "generates inserted_at and updated_at values" do
      # ...
      # lots of test code here
      # ...
    end
  end
  ```

  ### Using macro:

  ```
  describe "SomeSchema.insert/1" do
    test_insert_generate_uuid SomeSchema
    test_insert_generate_timestamps SomeSchema
  end
  ```
  """
  import EWalletDB.Factory
  alias Ecto.Adapters.SQL
  alias EWalletDB.{User, Account}

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import EWalletDB.{Factory, SchemaCase}
      alias Ecto.Adapters.SQL
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
        %{} = get_or_insert_master_account()
        :ok
      end
    end
  end

  def prepare_admin_user do
    {user, _} = insert_user_with_role("admin")
    user
  end

  def insert_user_with_role(role_name) do
    user = insert(:user)
    account = insert(:account)
    role = insert(:role, %{name: role_name})
    _membership = insert(:membership, %{user: user, account: account, role: role})

    {User.get(user.id), account}
  end

  def get_or_insert_master_account do
    case Account.get_master_account() do
      %{} = account ->
        account

      _ ->
        insert(:account, %{parent: nil})
    end
  end

  @doc """
  Test schema's factory produces params that can be inserted successfully.
  """
  defmacro test_has_valid_factory(schema) do
    quote do
      test "produces valid params and inserts successfully" do
        schema = unquote(schema)

        {res, val} =
          schema
          |> get_factory
          |> params_for
          |> schema.insert()

        assert res == :ok
      end
    end
  end

  defmacro test_schema_all_returns_all_records(schema, count) do
    quote do
      test "returns all existing #{unquote(schema)} records" do
        schema = unquote(schema)
        count = unquote(count)

        assert Enum.empty?(schema.all())

        for n <- 1..count do
          schema
          |> get_factory
          |> params_for
          |> schema.insert()
        end

        assert length(schema.all()) == count
      end
    end
  end

  @doc """
  Test schema's get/1 returns the struct if the given id is found
  """
  defmacro test_schema_get_returns_struct_if_given_valid_id(schema) do
    quote do
      test "returns a struct if given a valid id" do
        schema = unquote(schema)

        inserted =
          schema
          |> get_factory()
          |> insert()

        result = schema.get(inserted.id)

        assert result.id == inserted.id
      end
    end
  end

  defmacro test_schema_get_returns_nil_for_id(schema, id) do
    quote do
      test "returns a struct if given '#{unquote(id)}' as id" do
        schema = unquote(schema)
        id = unquote(id)

        assert schema.get(id) == nil
      end
    end
  end

  defmacro test_schema_get_accepts_preload(schema, preload) do
    quote do
      test "accepts :preload option with #{unquote(preload)}" do
        schema = unquote(schema)
        preload = unquote(preload)

        inserted =
          schema
          |> get_factory()
          |> insert()

        result = schema.get(inserted.id, preload: preload)

        assert result.id == inserted.id
        assert Ecto.assoc_loaded?(Map.get(result, preload))
      end
    end
  end

  defmacro test_schema_get_by_allows_search_by(schema, attr) do
    quote do
      test "searches by attribute #{unquote(attr)}" do
        schema = unquote(schema)
        attr = unquote(attr)

        inserted =
          schema
          |> get_factory()
          |> insert()

        {:ok, value} = Map.fetch(inserted, attr)

        result = schema.get_by(%{attr => value})
        assert Map.get(result, attr) == Map.get(inserted, attr)
      end
    end
  end

  @doc """
  Test schema's insert/1 with a specific field value is successful.
  """
  defmacro test_insert_ok(schema, field, value) when is_atom(field) do
    quote do
      test "inserts #{unquote(field)} successfully" do
        schema = unquote(schema)
        field = unquote(field)
        value = unquote(value)

        {res, val} =
          schema
          |> get_factory
          |> params_for(%{field => value})
          |> schema.insert()

        assert res == :ok
        assert Map.fetch!(val, field) == value
      end
    end
  end

  @doc """
  Test schema's insert/1 generates a uuid when given field is blank.
  """
  defmacro test_insert_generate_uuid(schema, field) do
    quote do
      test "generates a UUID for :#{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)

        {res, record} =
          schema
          |> get_factory
          |> params_for(%{field => nil})
          |> schema.insert

        assert res == :ok
        assert String.match?(record.unquote(field), ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
      end
    end
  end

  @doc """
  Test schema's insert/1 generates an external ID when given field is blank.
  """
  defmacro test_insert_generate_external_id(schema, field, prefix \\ "") do
    quote do
      test "generates an external ID" do
        schema = unquote(schema)
        field = unquote(field)
        prefix = unquote(prefix)

        {res, record} =
          schema
          |> get_factory
          |> params_for(%{field => nil})
          |> schema.insert

        assert res == :ok
        external_id = record.unquote(field)

        case prefix do
          "" ->
            assert String.length(external_id) == 26

          _ ->
            assert String.starts_with?(external_id, prefix)
            assert String.length(external_id) == String.length(prefix) + 26
        end
      end
    end
  end

  @doc """
  Test schema's insert/1 generates timestamps when respective fields are blank.
  """
  defmacro test_insert_generate_timestamps(schema) do
    quote do
      test "generates inserted_at and updated_at values" do
        schema = unquote(schema)

        {res, record} =
          schema
          |> get_factory
          |> params_for(%{inserted_at: nil, updated_at: nil})
          |> schema.insert

        assert res == :ok
        assert record.inserted_at != nil
        assert record.updated_at != nil
      end
    end
  end

  @doc """
  Test schema's insert/1 generates a string with given length
  when the given field is blank.
  """
  defmacro test_insert_generate_length(schema, field, len) do
    quote do
      test "generates a string with length #{unquote(len)} into :#{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)
        len = unquote(len)

        {res, record} =
          schema
          |> get_factory
          |> params_for(%{field => nil})
          |> schema.insert

        assert res == :ok
        assert String.length(Map.fetch!(record, field)) == len
      end
    end
  end

  @doc """
  Test schema's insert/1 prevents insert if given field is blank.
  """
  defmacro test_insert_prevent_blank(schema, field) when is_atom(field) do
    quote do
      test "prevents creation with blank :#{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(%{field => ""})
          |> schema.insert

        assert result == :error
        assert changeset.errors == [{field, {"can't be blank", [validation: :required]}}]
      end
    end
  end

  @doc """
  Test schema's insert/1 prevents insert if given association is missing.
  """
  defmacro test_insert_prevent_blank_assoc(schema, field) when is_atom(field) do
    quote do
      test "prevents creation with missing association :#{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)
        uuid_field = :"#{field}_uuid"

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(%{field => nil, uuid_field => nil})
          |> schema.insert()

        assert result == :error
        assert changeset.errors == [{uuid_field, {"can't be blank", [validation: :required]}}]
      end
    end
  end

  @doc """
  Test schema's insert/1 prevents insert if given field is blank.
  """
  defmacro test_insert_prevent_all_blank(schema, fields) when is_list(fields) do
    quote do
      test "prevents creation when all are blank: :#{Enum.join(unquote(fields), ", ")}" do
        schema = unquote(schema)
        fields = unquote(fields)

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(Map.new(fields, fn field -> {field, nil} end))
          |> schema.insert

        reason = changeset.errors |> List.first() |> elem(1) |> elem(0)

        assert result == :error
        assert reason == "can't all be blank"
      end
    end
  end

  @doc """
  Test schema's insert/1 allows insert if given field value already exists.
  """
  defmacro test_insert_allow_duplicate(schema, field, value \\ "same") do
    quote do
      test "allows insert with existing :#{unquote(field)} value" do
        schema = unquote(schema)
        field = unquote(field)
        value = unquote(value)

        {:ok, _record} =
          schema
          |> get_factory
          |> params_for(%{field => value})
          |> schema.insert

        {result, _record} =
          schema
          |> get_factory
          |> params_for(%{field => value})
          |> schema.insert

        assert result == :ok
      end
    end
  end

  @doc """
  Test schema's insert/1 prevents insert if given field value already exists.
  """
  defmacro test_insert_prevent_duplicate(schema, field, value \\ "same") do
    quote do
      test "returns error if same :#{unquote(field)} already exists" do
        schema = unquote(schema)
        field = unquote(field)
        value = unquote(value)

        {:ok, _record} =
          schema
          |> get_factory
          |> params_for(%{field => value})
          |> schema.insert

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(%{field => value})
          |> schema.insert

        assert result == :error
        assert changeset.errors == [{field, {"has already been taken", []}}]
      end
    end
  end

  @doc """
  Test schema's update/2 does update the given field
  """
  defmacro test_update_field_ok(schema, field, originator, old \\ "old", new \\ "new") do
    quote do
      test "updates #{unquote(field)} successfully" do
        schema = unquote(schema)
        field = unquote(field)
        originator = unquote(originator)
        old = unquote(old)
        new = unquote(new)

        {res, original} =
          schema
          |> get_factory
          |> params_for(%{field => old})
          |> schema.insert()

        {res, updated} =
          schema.update(original, %{
            :originator => originator,
            field => new
          })

        assert res == :ok
        assert Map.fetch!(updated, field) == new
      end
    end
  end

  @doc """
  Test schema's update/2 prevents changing of the given field
  """
  defmacro test_update_prevents_changing(schema, field, old \\ "old", new \\ "new") do
    quote do
      test "prevents changing of #{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)
        old = unquote(old)
        new = unquote(new)

        {res, original} =
          schema
          |> get_factory
          |> params_for(%{field => old})
          |> schema.insert()

        {res, changeset} = schema.update(original, %{field => new})

        assert res == :error
        assert changeset.errors == [{field, {"can't be changed", []}}]
      end
    end
  end

  @doc """
  Test schema's update/2 ignores changing of the given field
  """
  defmacro test_update_ignores_changing(schema, field, old \\ "old", new \\ "new") do
    quote do
      test "prevents changing of #{unquote(field)}" do
        schema = unquote(schema)
        field = unquote(field)
        old = unquote(old)
        new = unquote(new)

        {res, original} =
          schema
          |> get_factory
          |> params_for(%{field => old})
          |> schema.insert()

        {res, updated} = schema.update(original, %{field => new})

        assert res == :ok
        assert Map.fetch!(updated, field) == old
      end
    end
  end

  @doc """
  Test schema's metadata and encrypted metadata
  """
  defmacro test_default_metadata_fields(schema, table) do
    quote do
      test "sets the metadata and encrypted metadata to default values" do
        schema = unquote(schema)
        table = unquote(table)

        {_, record} =
          schema
          |> get_factory()
          |> params_for(metadata: nil, encrypted_metadata: nil)
          |> schema.insert()

        {:ok, results} =
          SQL.query(EWalletDB.Repo, "SELECT metadata, encrypted_metadata FROM \"#{table}\"", [])

        assert record.metadata == %{}
        assert record.encrypted_metadata == %{}
      end
    end
  end

  @doc """
  Test schema's field encryption for the given field
  """
  defmacro test_encrypted_map_field(schema, table, field) do
    quote do
      test "saves #{unquote(field)} as encrypted data" do
        schema = unquote(schema)
        table = unquote(table)
        field = unquote(field)

        {_, record} =
          schema
          |> get_factory()
          |> params_for(%{field => %{"something" => "cool"}})
          |> schema.insert()

        {:ok, results} = SQL.query(EWalletDB.Repo, "SELECT #{field} FROM \"#{table}\"", [])
        row = Enum.at(results.rows, 0)
        assert <<1, 10, "AES.GCM.V1", _::binary>> = Enum.at(row, 0)
        assert Map.get(record, field) == %{"something" => "cool"}
      end
    end
  end

  defmacro test_deleted_checks_nil_deleted_at(schema) do
    quote do
      test "returns false if deleted_at is nil" do
        schema = unquote(schema)

        {:ok, record} =
          schema
          |> get_factory()
          |> params_for(%{})
          |> schema.insert()

        assert record.deleted_at == nil
        refute schema.deleted?(record)
      end

      test "returns true if deleted_at is not nil" do
        schema = unquote(schema)

        {:ok, record} =
          schema
          |> get_factory()
          |> params_for(%{})
          |> schema.insert()

        {:ok, record} = schema.delete(record)

        assert record.deleted_at != nil
        assert schema.deleted?(record)
      end
    end
  end

  defmacro test_delete_causes_record_deleted(schema) do
    quote do
      test "causes the record to become deleted" do
        schema = unquote(schema)

        {_, record} =
          schema
          |> get_factory()
          |> params_for(%{})
          |> schema.insert()

        # Makes sure the record is not already deleted before testing
        refute schema.deleted?(record)

        {res, record} = schema.delete(record)
        assert res == :ok
        assert schema.deleted?(record)
      end
    end
  end

  defmacro test_restore_causes_record_undeleted(schema) do
    quote do
      test "causes the record to become undeleted" do
        schema = unquote(schema)

        {_, record} =
          schema
          |> get_factory()
          |> params_for(%{})
          |> schema.insert()

        # Makes sure the record is already soft-deleted before testing
        {:ok, record} = schema.delete(record)
        assert schema.deleted?(record)

        {res, record} = schema.restore(record)

        assert res == :ok
        refute schema.deleted?(record)
      end
    end
  end
end
