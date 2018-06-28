defmodule EWalletDB.Membership do
  @moduledoc """
  Ecto Schema representing user memberships.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account, Membership, Role, User}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "membership" do
    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :role,
      Role,
      foreign_key: :role_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  def changeset(%Membership{} = membership, attrs) do
    membership
    |> cast(attrs, [:user_uuid, :account_uuid, :role_uuid])
    |> validate_required([:user_uuid, :account_uuid, :role_uuid])
    |> unique_constraint(:user_uuid, name: :membership_user_id_account_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:account)
    |> assoc_constraint(:role)
  end

  @doc """
  Retrieves the membership for the given user and account.
  """
  def get_by_user_and_account(user, account) do
    Repo.get_by(Membership, %{user_uuid: user.uuid, account_uuid: account.uuid})
  end

  @doc """
  Retrieves all memberships for the given user.
  """
  def all_by_user(user, preload \\ []) do
    Repo.all(from(m in Membership, where: m.user_uuid == ^user.uuid, preload: ^preload))
  end

  def all_by_user_and_role(user, role) do
    Repo.all(
      from(m in Membership, where: m.user_uuid == ^user.uuid and m.role_uuid == ^role.uuid)
    )
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
        case allowed?(user, account, role) do
          true ->
            insert(%{
              account_uuid: account.uuid,
              user_uuid: user.uuid,
              role_uuid: role.uuid
            })
          false ->
            {:error, :user_already_has_rights}
        end

      existing ->
        update(existing, %{role_uuid: role.uuid})
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

  defp allowed?(user, account, role) do
    ancestors = Account.get_all_ancestors(account)
    memberships = Membership.all_by_user(user, [:role, :account])

    ancestors_uuids = Enum.map(ancestors, fn ancestor -> ancestor.uuid end)
    membership_accounts_uuids = Enum.map(memberships, fn membership -> membership.account_uuid end)

    case intersect(ancestors_uuids, membership_accounts_uuids) do
      [] ->
        descendants = Account.get_all_descendants(account)
        descendants_uuids = Enum.map(descendants, fn descendant -> descendant.uuid end)
          case intersect(descendants_uuids, membership_accounts_uuids) do
            [] ->
              true
            matching_descendant_uuids ->
              Enum.map(matching_descendant_uuids, fn matching_descendant_uuid ->
                membership = Enum.find(memberships, fn membership ->
                  membership.account_uuid == matching_descendant_uuid
                end)

                case role.priority <= membership.role.priority do
                  true ->
                    unassign(user, membership.account)
                    true
                  false ->
                    true
                end
              end)

              true
          end

      [matching_ancestor_uuid] ->
        membership = Enum.find(memberships, fn membership ->
          membership.account_uuid == matching_ancestor_uuid
        end)

        role.priority <= membership.role.priority
    end
  end

  defp intersect(a, b), do: a -- a -- b
end
