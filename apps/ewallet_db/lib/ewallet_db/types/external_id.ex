defmodule EWalletDB.Types.ExternalID do
  @moduledoc """
  A custom Ecto type that handles the external ID. The external ID is a string
  that consists of a ULID prefixed with a 3-letter symbol representing the schema
  that the external ID belongs to.

  The external ID is always in lower case.

  Although this custom type is a straight-forward string primitive, it validates
  the given external ID before allowing the value to be casted. Hence it gives a
  better assurance that the value stored by this type follows a consistent format.

  This module also provides a helper macro `external_id/1` for setting up a schema field
  that autogenerates the external ID.
  """
  @behaviour Ecto.Type
  alias Ecto.Schema
  alias ExULID.ULID

  # 3-char symbols, 1-char underscore, 26-char ULID
  @type t :: <<_::30>>

  @doc """
  Returns the underlying Ecto primitive type.
  """
  def type, do: :string

  @doc """
  Casts the given input to the schema struct.

  Returns `{:ok, value}` on successful casting where `value` is a string of 3-character symbol,
  an underscore and 26-character ULID string. Returns `:error` on failure.
  """
  @spec cast(String.t()) :: {:ok, String.t()} | :error
  def cast(<<_::bytes-size(3), "_", _::bytes-size(26)>> = ulid_string) do
    {:ok, String.downcase(ulid_string)}
  end

  def cast(_), do: :error

  @doc """
  Transforms the value after loaded from the database.
  """
  @spec load(String.t()) :: {:ok, String.t()}
  def load(value), do: {:ok, value}

  @doc """
  Prepares the value for saving to database.
  """
  @spec dump(String.t()) :: {:ok, String.t()}
  def dump(value), do: {:ok, value}

  # The defaults to use to define the External ID field.
  @external_id_defaults [
    # The field name
    field_name: :id,
    # The prefix to prepend to the generated ULID
    prefix: "",
    # The function to use for autogenerating the value
    autogenerate: nil
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
        Schema.field(field_name, :string, [])
        Module.put_attribute(__MODULE__, :ecto_autogenerate, {field_name, autogen_fn})
      end
    end
  end

  @doc """
  Generates an external ID.

  Returns a ULID if the prefix is not given, otherwise prepends the ULID with the given prefix.
  """
  @spec generate(String.t()) :: String.t()
  def generate(<<symbol::bytes-size(3), "_">> = prefix) do
    if String.match?(symbol, ~r/^[0-9a-z]{3}$/) do
      String.downcase(prefix <> ULID.generate())
    else
      :error
    end
  end

  def generate(_), do: :error

  # Callback invoked by autogenerate fields.
  @doc false
  def autogenerate(prefix), do: generate(prefix)

  # A custom guard that validates the input for external ID
  # Ref: https://stackoverflow.com/questions/21261696/create-new-guard-clause
  defmacro is_external_id(id) do
    quote do
      # is a string
      # 4th character is an underscore
      # 3-char symbol, 1-char underscore, 26-char ULID
      is_binary(unquote(id)) and binary_part(unquote(id), 3, 1) == "_" and
        byte_size(unquote(id)) == 30
    end
  end

  defmacro __using__(_) do
    quote do
      alias EWalletDB.Types.ExternalID
      import EWalletDB.Types.ExternalID, only: [external_id: 1, is_external_id: 1]
    end
  end
end
