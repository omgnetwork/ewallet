defmodule EWalletDB.Token do
  @moduledoc """
  Ecto Schema representing tokens.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, Token}
  alias ExULID.ULID

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "token" do
    # tok_eur_01cbebcdjprhpbzp1pt7h0nzvt
    field(:id, :string)

    # "eur"
    field(:symbol, :string)
    # "EUR"
    field(:iso_code, :string)
    # "Euro"
    field(:name, :string)
    # Official currency of the European Union
    field(:description, :string)
    # "€"
    field(:short_symbol, :string)
    # "Cent"
    field(:subunit, :string)
    # 100
    field(:subunit_to_unit, EWalletDB.Types.Integer)
    # true
    field(:symbol_first, :boolean)
    # "&#x20AC;"
    field(:html_entity, :string)
    # "978"
    field(:iso_numeric, :string)
    # 1
    field(:smallest_denomination, :integer)
    # false
    field(:locked, :boolean)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  defp changeset(%Token{} = token, attrs) do
    token
    |> cast(attrs, [
      :symbol,
      :iso_code,
      :name,
      :description,
      :short_symbol,
      :subunit,
      :subunit_to_unit,
      :symbol_first,
      :html_entity,
      :iso_numeric,
      :smallest_denomination,
      :locked,
      :account_uuid,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_required([
      :symbol,
      :name,
      :subunit_to_unit,
      :account_uuid,
      :metadata,
      :encrypted_metadata
    ])
    |> validate_number(:subunit_to_unit, greater_than: 0, less_than_or_equal_to: 1.0e18)
    |> validate_immutable(:symbol)
    |> unique_constraint(:symbol)
    |> unique_constraint(:iso_code)
    |> unique_constraint(:name)
    |> unique_constraint(:short_symbol)
    |> unique_constraint(:iso_numeric)
    |> assoc_constraint(:account)
    |> put_change(:encryption_version, Cloak.version())
    |> set_id(prefix: "tok_")
  end

  defp set_id(changeset, opts) do
    case get_field(changeset, :id) do
      nil ->
        symbol = get_field(changeset, :symbol)
        ulid = ULID.generate()
        put_change(changeset, :id, build_id(symbol, ulid, opts))

      _ ->
        changeset
    end
  end

  defp build_id(symbol, ulid, opts) do
    case opts[:prefix] do
      nil ->
        "#{symbol}_#{ulid}"

      prefix ->
        "#{prefix}#{symbol}_#{ulid}"
    end
  end

  @doc """
  Returns all tokens in the system
  """
  def all do
    Repo.all(Token)
  end

  @doc """
  Create a new token with the passed attributes.
  """
  def insert(attrs) do
    changeset = changeset(%Token{}, attrs)

    case Repo.insert(changeset) do
      {:ok, token} ->
        {:ok, get(token.id)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Retrieve a token by id.
  """
  @spec get_by(String.t(), opts :: keyword()) :: %Token{} | nil
  def get(id, opts \\ [])
  def get(nil, _), do: nil

  def get(id, opts) do
    get_by([id: id], opts)
  end

  @doc """
  Retrieves a token using one or more fields.
  """
  @spec get_by(fields :: map(), opts :: keyword()) :: %Token{} | nil
  def get_by(fields, opts \\ []) do
    Token
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Retrieve a list of tokens by supplying a list of IDs.
  """
  def get_all(ids) do
    Repo.all(from(m in Token, where: m.id in ^ids))
  end
end
