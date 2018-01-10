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
    |> validate_required([:account_id, :user_id, :role_id])
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
    |> assoc_constraint(:role)
  end

  @doc """
  Assigns the user to the given account and role.
  """
  def assign(user, account, role) when is_atom(role) and not is_nil(role) do
    role = Role.get_by_name(role)
    assign(user, account, role)
  end
  def assign(%User{} = user, %Account{} = account, %Role{} = role) do
    insert(%{
      account_id: account.id,
      user_id: user.id,
      role_id: role.id
    })
  end
  def assign(_, _, nil), do: {:error, :role_not_found}

  defp insert(attrs) do
    %Membership{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Checks if the user is assigned to the given role, regardless of which account.
  """
  def user_has_role?(user, role) when is_atom(role) do
    user
    |> user_get_roles()
    |> Enum.member?(role)
  end

  @doc """
  Get the list of unique roles that the given user is assigned to, regardless of the account.
  """
  def user_get_roles(user) do
    user
    |> Repo.preload(:roles)
    |> Map.get(:roles, [])
    |> Enum.map(&Role.to_atom/1)
    |> Enum.uniq()
  end
end
