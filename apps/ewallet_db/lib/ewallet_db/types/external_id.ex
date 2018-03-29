defmodule EWalletDB.Types.ExternalID do
  @moduledoc """
  A custom Ecto type that handles the external ID. The external ID is a string
  that consists of a ULID prefixed with a 3-letter symbol representing the schema
  that the external ID belongs to.

  Although the this custom type is a straightforward string primitive, it validates
  the given external ID before allowing the value to be casted. Hence it gives a
  better assurance that the value stored by this type follows a consistent format.

  This module also provides a helper macro `external_id/1` for setting up a schema field
  that autogenerates the external ID.
  """
  @behaviour Ecto.Type
  alias ExULID.ULID

  @doc """
  Returns the underlying Ecto primitive type.
  """
  def type, do: :string

  @doc """
  Casts the given input to the schema struct.

  Returns `{:ok, value}` on successful casting, `:error` on failure.
  """
  @spec cast(String.t) :: {:ok, String.t} | :error
  def cast(value), do: {:ok, value}

  @doc """
  Transforms the value after loaded from the database.
  """
  @spec load(String.t) :: {:ok, String.t}
  def load(value), do: {:ok, value}

  @doc """
  Prepares the value for saving to database.
  """
  @spec dump(String.t) :: {:ok, String.t}
  def dump(value), do: {:ok, value}

  # The defaults to use to define the External ID field.
  @external_id_defaults [
    field_name: :external_id, # The field name
    prefix: "", # The prefix to prepend to the generated ULID
    autogenerate: nil # The function to use for autogenerating the value
  ]

  @doc """
  Defines a prefixed-UULID field on a schema with given prefix.

  ## Example
  defmodule ExampleSchema do
    use EWalletDB.Types.ExternalID

    schema "examples" do
      external_id prefix: "exp_"
    end
  end
  """
  defmacro external_id(opts \\ []) do
    opts = Keyword.merge(@external_id_defaults, opts)
    type = __MODULE__

    quote bind_quoted: binding() do
      autogen_fn = opts[:autogenerate] || {type, :autogenerate, [opts[:prefix]]}

      if field_name = Keyword.fetch!(opts, :field_name) do
        Ecto.Schema.field(field_name, :string, [])
        Module.put_attribute(__MODULE__, :ecto_autogenerate, {field_name, autogen_fn})
      end
    end
  end

  @doc """
  Generates an external ID.

  Returns a ULID if the prefix is not given, otherwise prepends the ULID with the given prefix.
  """
  def generate(nil), do: ULID.generate()
  def generate(prefix), do: prefix <> ULID.generate()

  # Callback invoked by autogenerate fields.
  @doc false
  def autogenerate(prefix), do: generate(prefix)

  defmacro __using__(_) do
    quote do
      import EWalletDB.Types.ExternalID, only: [external_id: 1]
    end
  end
end
