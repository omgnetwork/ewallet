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
      :address, :account_id, :minted_token_id, :user_id, :metadata
    ])
    |> validate_required(:address)
    |> validate_required_exclusive([:account_id, :minted_token_id, :user_id])
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
end
