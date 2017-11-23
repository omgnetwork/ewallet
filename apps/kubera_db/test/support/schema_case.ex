defmodule KuberaDB.SchemaCase do
  @moduledoc """
  This module defines common behaviors shared for KuberaDB schema tests.

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
  import KuberaDB.Factory
  alias Ecto.Adapters.SQL

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      import KuberaDB.{Factory, SchemaCase}
      alias Ecto.Adapters.SQL
      alias Ecto.Adapters.SQL.Sandbox
      alias KuberaDB.Repo

      setup do
        :ok = Sandbox.checkout(Repo)
      end
    end
  end

  @doc """
  Test schema's factory produces params that can be inserted successfully.
  """
  defmacro test_has_valid_factory(schema) do
    quote do
      test "produces valid params and insert successfully" do
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

  @doc """
  Test schema's insert/1 with a specific field value is successful.
  """
  defmacro test_insert_ok(schema, field, value) when is_atom(field) do
    quote do
      test "inserts #{unquote field} successfully" do
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
      test "generates a UUID for :#{unquote field}" do
        schema = unquote(schema)
        field  = unquote(field)

        {res, record} =
          schema
          |> get_factory
          |> params_for(%{field => nil})
          |> schema.insert

        assert res == :ok
        assert String.match?(record.unquote(field),
          ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
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
      test "generates a string with length #{unquote len} into :#{unquote field}" do
        schema = unquote(schema)
        field  = unquote(field)
        len  = unquote(len)

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
      test "prevents creation with blank :#{unquote field}" do
        schema = unquote(schema)
        field = unquote(field)

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(%{field => ""})
          |> schema.insert

        assert result == :error
        assert changeset.errors ==
          [{field, {"can't be blank", [validation: :required]}}]
      end
    end
  end

  @doc """
  Test schema's insert/1 prevents insert if given association is missing.
  """
  defmacro test_insert_prevent_blank_assoc(schema, field) when is_atom(field) do
    quote do
      test "prevents creation with missing association :#{unquote field}" do
        schema = unquote(schema)
        field = unquote(field)

        {result, changeset} =
          schema
          |> get_factory
          |> params_for(%{field => ""})
          |> schema.insert

        assert result == :error
        assert changeset.errors ==
          [{:"#{field}_id", {"can't be blank", [validation: :required]}}]
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

        reason = changeset.errors |> List.first |> elem(1) |> elem(0)

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
      test "allows insert with existing :#{unquote field} value" do
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
      test "returns error if same :#{unquote field} already exists" do
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
  defmacro test_update_field_ok(schema, field, old \\ "old", new \\ "new") do
    quote do
      test "updates #{unquote field} successfully" do
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
        assert Map.fetch!(updated, field) == new
      end
    end
  end

  @doc """
  Test schema's update/2 prevents changing of the given field
  """
  defmacro test_update_prevents_changing(schema, field) do
    quote do
      test "prevents changing of #{unquote field}" do
        schema = unquote(schema)
        field = unquote(field)

        {res, original} =
          schema
          |> get_factory
          |> params_for(%{field => "old_value"})
          |> schema.insert()

        {res, changeset} = schema.update(original, %{field => "new_value"})

        assert res == :error
        assert changeset.errors == [{field, {"can't be changed", []}}]
      end
    end
  end

  @doc """
  Test schema's field encryption for the given field
  """
  defmacro test_encrypted_map_field(schema, table, field) do
    quote do
      test "saves #{unquote field} as encrypted data" do
        schema = unquote(schema)
        table = unquote(table)
        field = unquote(field)

        {_, record} =
          schema
          |> get_factory()
          |> params_for(%{field => %{something: "cool"}})
          |> schema.insert()

        {:ok, results} = SQL.query(KuberaDB.Repo, "SELECT #{field} FROM \"#{table}\"", [])
        row = Enum.at(results.rows, 0)
        assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)
        assert Map.get(record, field) == %{"something" => "cool"}
      end
    end
  end
end
