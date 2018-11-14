defmodule EWalletConfig.Types.WalletAddress do
  @moduledoc """
  A custom Ecto type that handles wallet addresses. A wallet address is a string
  that consists of 4 case-insensitive letters followed by a 12-digit integer.
  All non-alphanumerics are stripped and ignored.

  Although this custom type is a straight-forward string primitive, it validates
  the given wallet address before allowing the value to be casted. Hence it gives
  a better assurance that the value stored by this type follows a consistent format.

  This module also provides a helper macro `wallet_address/1` for setting up
  a schema field that autogenerates the wallet address.
  """
  @behaviour Ecto.Type
  alias Ecto.Schema
  alias EWalletConfig.Helpers.UUID

  # 4-char letters, 12-digit integers
  @type t :: <<_::16>>

  # The alphabets to use for randoming the wallet address
  @alphabets "abcdefghijklmnopqrstuvwxyz"

  # The numbers to use for randoming the wallet address
  @numbers "0123456789"

  # The defaults to use to define the field.
  @default_opts [
    # The string to use as the 4-letter at the beginning of the address.
    prefix: nil,
    # The function to use for autogenerating the value.
    autogenerate: nil
  ]

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
  def cast(address) do
    # We still want to support the old UUID format.
    case UUID.valid?(address) do
      true ->
        {:ok, address}

      _ ->
        address =
          address
          |> String.replace(~r/[^A-Za-z0-9]/, "")
          |> String.downcase()

        case String.match?(address, ~r/^[a-z0-9]{4}[0-9]{12}$/) do
          true -> {:ok, address}
          _ -> :error
        end
    end
  end

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

  @doc """
  Defines a wallet address field on a schema.

  ## Example
  defmodule WalletSchema do
    use EWalletConfig.Types.WalletAddress

    schema "wallet" do
      wallet_address(:address)
    end
  end
  """
  defmacro wallet_address(field_name, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    type = __MODULE__

    quote bind_quoted: binding() do
      autogen_fn = opts[:autogenerate] || {type, :autogenerate, [opts[:prefix]]}

      Schema.field(field_name, type, [])
      Module.put_attribute(__MODULE__, :ecto_autogenerate, {field_name, autogen_fn})
    end
  end

  @doc """
  Generates a new wallet address with the format `aaaa000000000000`,
  where `a` is a random a-z letter and `0` is a random 1-digit integer.

  Returns `{:ok, address}`.
  """
  @spec generate() :: {:ok, String.t()}
  def generate do
    prefix = random(4, @alphabets)
    generate(prefix)
  end

  @doc """
  Generates a new wallet address. Accepts up to 4-letter prefix,
  uses it as the address's prefix and randomize the rest with integers.

  Returns `{:ok, address}` on success.
  Returns `:error` if more than 4 letters or invalid characters are given.
  """
  @spec generate(String.t() | nil) :: String.t() | :error
  def generate(prefix) when byte_size(prefix) <= 4 do
    case String.match?(prefix, ~r/^[a-z0-9]*$/) do
      true ->
        random_length = 16 - String.length(prefix)
        {:ok, prefix <> random(random_length, @numbers)}

      false ->
        :error
    end
  end

  def generate(nil), do: generate()

  def generate(_), do: :error

  defp random(output_length, pool) when is_binary(pool) do
    random(output_length, String.split(pool, "", trim: true))
  end

  defp random(output_length, pool) do
    1..output_length
    |> Enum.reduce([], fn _, acc -> [Enum.random(pool) | acc] end)
    |> Enum.join("")
  end

  # Callback invoked by autogenerate fields.
  @doc false
  def autogenerate(prefix) do
    {:ok, address} = generate(prefix)
    address
  end

  defmacro __using__(_) do
    quote do
      import EWalletConfig.Types.WalletAddress, only: [wallet_address: 1, wallet_address: 2]
    end
  end
end
