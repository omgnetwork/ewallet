defmodule EWalletDB.Membership do
  @moduledoc """
  Ecto Schema representing user memberships.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, Membership, Role, User}

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

  @doc """
  Retrieves the membership for the given user and account.
  """
  def get_by_user_and_account(user, account) do
    Repo.get_by(Membership, %{user_id: user.id, account_id: account.id})
  end

  @doc """
  Assigns the user to the given account and role.
  """
  def assign(user, account, role) when is_binary(role) do
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

  defp delete(%Membership{} = membership) do
    Repo.delete(membership)
  end

  @doc """
  Checks if the user belongs to any account, regardless of the role.
  """
  # User does not have any membership if it has not been saved yet.
  # Without pattern matching for nil id, Ecto will return an unsafe nil comparison error.
  def user_has_membership?(%{id: nil}), do: false
  def user_has_membership?(user) do
    query = from(m in Membership, where: m.user_id == ^user.id)
    Repo.aggregate(query, :count, :id) > 0
  end

  @doc """
  Checks if the user is assigned to the given role, regardless of which account.
  """
  def user_has_role?(user, role) do
    user
    |> user_get_roles()
    |> Enum.member?(role)
  end

  @doc """
  Get the list of unique roles that the given user is assigned to, regardless of the account.

  This is useful when a check is required on a role but not depending on the account.
  E.g. if the user is an admin, an email and password is required regardless of which account.
  """
  def user_get_roles(user) do
    user
    |> Repo.preload(:roles)
    |> Map.get(:roles, [])
    |> Enum.map(fn(role) -> Map.fetch!(role, :name) end)
    |> Enum.uniq()
  end
end
