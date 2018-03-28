defmodule EWalletDB.MintedToken do
  @moduledoc """
  Ecto Schema representing minted tokens.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, MintedToken}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "minted_token" do
    field :friendly_id, :string # "EUR:123"
    field :symbol, :string # "eur"
    field :iso_code, :string # "EUR"
    field :name, :string # "Euro"
    field :description, :string # Official currency of the European Union
    field :short_symbol, :string # "€"
    field :subunit, :string # "Cent"
    field :subunit_to_unit, EWalletDB.Types.Integer # 100
    field :symbol_first, :boolean # true
    field :html_entity, :string # "&#x20AC;"
    field :iso_numeric, :string # "978"
    field :smallest_denomination, :integer # 1
    field :locked, :boolean # false
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}
    field :encryption_version, :binary
    belongs_to :account, Account, foreign_key: :account_id,
                                           references: :id,
                                           type: UUID
    timestamps()
  end

  defp changeset(%MintedToken{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [
      :symbol, :iso_code, :name, :description, :short_symbol,
      :subunit, :subunit_to_unit, :symbol_first, :html_entity,
      :iso_numeric, :smallest_denomination, :locked, :account_id,
      :metadata, :encrypted_metadata, :friendly_id
    ])
    |> validate_required([
      :symbol, :name, :subunit_to_unit, :account_id,
      :metadata, :encrypted_metadata
    ])
    |> validate_number(:subunit_to_unit, greater_than: 0, less_than: 1.0e81)
    |> set_friendly_id()
    |> validate_required([:friendly_id])
    |> validate_immutable(:friendly_id)
    |> unique_constraint(:symbol)
    |> unique_constraint(:iso_code)
    |> unique_constraint(:name)
    |> unique_constraint(:short_symbol)
    |> unique_constraint(:iso_numeric)
    |> assoc_constraint(:account)
    |> put_change(:encryption_version, Cloak.version)
  end

  defp set_friendly_id(changeset) do
    case get_field(changeset, :friendly_id) do
      nil ->
        symbol = get_field(changeset, :symbol)
        uuid = UUID.generate()

        changeset
        |> put_change(:id, uuid)
        |> put_change(:friendly_id, build_friendly_id(symbol, uuid))
      _ -> changeset
    end
  end

  def build_friendly_id(symbol, uuid) do
    "#{symbol}:#{uuid}"
  end

  @doc """
  Returns all minted tokens in the system
  """
  def all do
    Repo.all(MintedToken)
  end

  @doc """
  Create a new minted token with the passed attributes.
  """
  def insert(attrs) do
    changeset = changeset(%MintedToken{}, attrs)

    case Repo.insert(changeset) do
      {:ok, minted_token} ->
        {:ok, get(minted_token.friendly_id)}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Retrieve a minted token by friendly_id.
  """
  def get(nil), do: nil
  def get(friendly_id) do
    Repo.get_by(MintedToken, friendly_id: friendly_id)
  end

  @doc """
  Retrieve a list of minted tokens by supplying a list of friendly IDs.
  """
  def get_all(friendly_ids) do
    Repo.all(from m in MintedToken,
                       where: m.friendly_id in ^friendly_ids)
  end
end
