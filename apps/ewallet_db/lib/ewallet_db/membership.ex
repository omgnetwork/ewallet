# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.Membership do
  @moduledoc """
  Ecto Schema representing user memberships.
  """
  use Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]
  alias Ecto.UUID
  alias EWalletDB.{Account, Membership, Repo, Role, User}

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
    activity_logging()
  end

  def changeset(%Membership{} = membership, attrs) do
    membership
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:user_uuid, :account_uuid, :role_uuid],
      required: [:user_uuid, :account_uuid, :role_uuid]
    )
    |> unique_constraint(:user_uuid, name: :membership_user_id_account_id_index)
    |> assoc_constraint(:user)
    |> assoc_constraint(:account)
    |> assoc_constraint(:role)
  end

  @doc """
  Retrieves the membership for the given user and account.
  """
  def get_by_user_and_account(user, account) do
    Membership
    |> Repo.get_by(%{user_uuid: user.uuid, account_uuid: account.uuid})
    |> Repo.preload([:role])
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

  def all_by_account_uuids(account_uuids, preload \\ []) do
    from(m in Membership, where: m.account_uuid in ^account_uuids, preload: ^preload)
  end

  def distinct_by_role(memberships) do
    memberships
    |> Enum.reduce(%{}, fn membership, map -> reduce_distinct(membership, map) end)
    |> Enum.map(fn {_uuid, membership} -> membership end)
  end

  defp reduce_distinct(membership, map) do
    case Map.get(map, membership.user_uuid) do
      nil ->
        Map.put(map, membership.user_uuid, membership)

      existing_membership ->
        if existing_membership.role.priority > membership.role.priority do
          Map.put(map, membership.user_uuid, membership)
        end
    end
  end

  @doc """
  Assigns the user to the given account and role.
  """
  def assign(user, account, role_name, originator) when is_binary(role_name) do
    case Role.get_by(name: role_name) do
      nil ->
        {:error, :role_not_found}

      role ->
        assign(user, account, role, originator)
    end
  end

  def assign(%User{} = user, %Account{} = account, %Role{} = role, originator) do
    case get_by_user_and_account(user, account) do
      nil ->
        insert(%{
          account_uuid: account.uuid,
          user_uuid: user.uuid,
          role_uuid: role.uuid,
          originator: originator
        })

      existing ->
        update(existing, %{
          role_uuid: role.uuid,
          originator: originator
        })
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign(%User{} = user, %Account{} = account, originator) do
    case get_by_user_and_account(user, account) do
      nil ->
        {:error, :membership_not_found}

      membership ->
        delete(membership, originator)
    end
  end

  defp insert(attrs) do
    %Membership{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  defp update(%Membership{} = membership, attrs) do
    membership
    |> changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  defp delete(%Membership{} = membership, originator) do
    membership
    |> changeset(%{
      originator: originator
    })
    |> Repo.delete_record_with_activity_log()
  end
end
