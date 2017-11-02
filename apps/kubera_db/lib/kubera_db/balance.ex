defmodule KuberaDB.Balance do
  @moduledoc """
  Ecto Schema representing balance.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import KuberaDB.Validator
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Balance, MintedToken, User}

  @primary_key {:id, UUID, autogenerate: true}

  schema "balance" do
    field :address, :string
    field :genesis, :boolean, default: false
    belongs_to :user, User, foreign_key: :user_id,
                            references: :id,
                            type: UUID
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    field :metadata, :map
    timestamps()
  end

  @doc """
  Validates balance data.
  """
  def changeset(%Balance{} = balance, attrs) do
    balance
    |> cast(attrs, [
      :address, :account_id, :minted_token_id, :user_id, :metadata, :genesis
    ])
    |> validate_required(:address)
    |> validate_required_exclusive([
      :account_id, :minted_token_id, :user_id, :genesis
    ])
    |> unique_constraint(:address)
    |> assoc_constraint(:account)
    |> assoc_constraint(:minted_token)
    |> assoc_constraint(:user)
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
  def genesis do
    case get("genesis") do
      nil ->
        insert_without_conflict("genesis", nil, true)
      balance ->
        {:ok, balance}
    end
  end

  @doc """
  Inserts a special kind of balance (either a genesis one or a master balance).
  """
  def insert_without_conflict(address, minted_token_id, genesis \\ false) do
    changeset = Balance.changeset(%Balance{}, %{
      address: address,
      minted_token_id: minted_token_id,
      genesis: genesis
    })
    opts = [on_conflict: :nothing, conflict_target: :address]

    case Repo.insert(changeset, opts) do
      {:ok, _balance} ->
        {:ok, get(address)}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
