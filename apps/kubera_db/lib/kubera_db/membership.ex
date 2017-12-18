defmodule KuberaDB.Membership do
  @moduledoc """
  Ecto Schema representing user memberships.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Membership, Role, User}

  @primary_key false

  schema "membership" do
    belongs_to :account, Account, type: UUID
    belongs_to :user, User, type: UUID
    belongs_to :role, Role, type: UUID

    timestamps()
  end

  def changeset(%Membership{} = membership, attrs) do
    membership
    |> cast(attrs, [:account_id, :user_id, :role_id])
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
    |> assoc_constraint(:role)
  end

  @doc """
  Creates a new membership with the passed attributes.
  """
  def insert(attrs) do
    %Membership{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
