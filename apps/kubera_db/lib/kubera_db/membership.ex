defmodule KuberaDB.Membership do
  @moduledoc """
  Ecto Schema representing user memberships.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, Membership, Role, User}

  @primary_key {:id, UUID, autogenerate: true}

  schema "membership" do
    belongs_to :user, User, type: UUID
    belongs_to :account, Account, type: UUID
    belongs_to :role, Role, type: UUID

    timestamps()
  end

  def changeset(%Membership{} = membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :account_id, :role_id])
    |> validate_required([:user_id, :account_id, :role_id])
    |> unique_constraint(:user_id, name: :membership_user_id_account_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:account)
    |> assoc_constraint(:role)
  end

  defp get_by_user_and_account(user, account) do
    Repo.get_by(Membership, %{user_id: user.id, account_id: account.id})
  end

  @doc """
  Assigns the user to the given account and role.
  """
  def assign(user, account, role) when is_atom(role) and not is_nil(role) do
    case Role.get_by_name(role) do
      nil ->
        {:error, :role_not_found}
      role ->
        assign(user, account, role)
    end
  end
  def assign(%User{} = user, %Account{} = account, %Role{} = role) do
    case get_by_user_and_account(user, account) do
      nil ->
        insert(%{
          account_id: account.id,
          user_id: user.id,
          role_id: role.id
        })
      existing ->
        update(existing, %{role_id: role.id})
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign(%User{} = user, %Account{} = account) do
    case get_by_user_and_account(user, account) do
      nil ->
        {:error, :membership_not_found}
      membership ->
        delete(membership)
    end
  end

  defp insert(attrs) do
    %Membership{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp update(%Membership{} = membership, attrs) do
    membership
    |> changeset(attrs)
    |> Repo.update()
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
