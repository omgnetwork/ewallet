defmodule KuberaDB.Balance do
  @moduledoc """
  Ecto Schema representing balance.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import KuberaDB.Validator
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Balance, MintedToken, User}

  @genesis   "genesis"
  @burn      "burn"
  @primary   "primary"
  @secondary "secondary"

  def genesis, do: @genesis
  def burn, do: @burn
  def primary, do: @primary
  def secondary, do: @secondary

  @primary_key {:id, UUID, autogenerate: true}

  schema "balance" do
    field :address, :string
    field :name, :string
    field :identifier, :string
    belongs_to :user, User, foreign_key: :user_id,
                            references: :id,
                            type: UUID
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary
    timestamps()
  end

  defp changeset(%Balance{} = balance, attrs) do
    balance
    |> cast(attrs, [
      :address, :account_id, :minted_token_id, :user_id, :metadata, :name, :identifier
    ])
    |> validate_required([:address, :name, :identifier])
    |> validate_format(:identifier, ~r/#{@genesis}|#{@burn}|#{@primary}|#{@secondary}:.*/)
    |> validate_required_exclusive(%{account_id: nil, user_id: nil, identifier: @genesis})
    |> unique_constraint(:address)
    |> assoc_constraint(:account)
    |> assoc_constraint(:minted_token)
    |> assoc_constraint(:user)
    |> unique_constraint(:unique_account_name, name: :balance_account_id_name_index)
    |> unique_constraint(:unique_user_name, name: :balance_user_id_name_index)
    |> unique_constraint(:unique_account_identifier, name: :balance_account_id_identifier_index)
    |> unique_constraint(:unique_user_identifier, name: :balance_user_id_identifier_index)
    |> put_change(:encryption_version, Cloak.version)
  end

  @doc """
  Retrieve a balance using the specified address.
  """
  def get(address) do
    Repo.get_by(Balance, address: address)
  end

  @doc """
  Create a new balance with the passed attributes.
  A UUID is generated as the address if address is not specified.
  """
  def insert(attrs) do
    attrs = attrs |> Map.put_new_lazy(:address, &UUID.generate/0)

    %Balance{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the genesis balance.
  """
  def get_genesis do
    case get(@genesis) do
      nil ->
        {:ok, genesis} = insert_genesis()
        genesis
      balance ->
        balance
    end
  end

  @doc """
  Inserts a genesis.
  """
  def insert_genesis do
    changeset = changeset(%Balance{}, %{address: @genesis, name: @genesis, identifier: @genesis})
    opts = [on_conflict: :nothing, conflict_target: :address]

    case Repo.insert(changeset, opts) do
      {:ok, _balance} ->
        {:ok, get(@genesis)}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
