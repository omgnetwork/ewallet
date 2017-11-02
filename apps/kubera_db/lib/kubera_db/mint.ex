defmodule KuberaDB.Mint do
  @moduledoc """
  Ecto Schema representing mints.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Mint, MintedToken}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "mint" do
    field :description, :string
    field :amount, KuberaDB.Types.Integer
    field :confirmed, :boolean, default: false
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    timestamps()
  end

  @doc """
  Validates mint data.

  ## Examples

      iex> changeset(%Mint{}, %{field: value})
      %Mint{}

  """
  def changeset(%Mint{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [:description, :amount, :minted_token_id, :confirmed])
    |> validate_required([:amount, :minted_token_id])
    |> assoc_constraint(:minted_token)
  end

  @doc """
  Create a new mint with the passed attributes.
  """
  def insert(attrs) do
    changeset = Mint.changeset(%Mint{}, attrs)
    Repo.insert(changeset)
  end

  def confirm(mint) do
    changeset = Mint.changeset(mint, %{confirmed: true})
    Repo.update(changeset)
  end
end
