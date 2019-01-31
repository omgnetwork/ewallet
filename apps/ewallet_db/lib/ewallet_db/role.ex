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

defmodule EWalletDB.Role do
  @moduledoc """
  Ecto Schema representing user roles.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use EWalletDB.SoftDelete
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Membership, Repo, Role, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @account_role_permissions %{
    admin: %{
      account: %{read: :accounts, update: :accounts},
      categories: %{read: :global},
      admin_users: %{read: :accounts, create: :accounts, update: :accounts},
      end_users: %{read: :accounts, create: :accounts, update: :accounts},
      access_keys: %{read: :accounts, create: :accounts, update: :accounts, disable: :accounts},
      api_keys: %{read: :accounts, create: :accounts, update: :accounts, disable: :accounts},
      tokens: %{read: :global},
      mints: :none,
      account_wallets: %{read: :global, view_balance: :accounts, create: :accounts, update: :accounts},
      end_user_wallets: %{read: :global, view_balance: :accounts, create: :accounts, update: :accounts},
      account_transactions: %{read: :accounts, create: :accounts},
      end_user_transactions: %{read: :accounts, create: :accounts},
      account_transaction_requests: %{read: :accounts, create: :accounts},
      end_user_transaction_requests: %{read: :accounts, create: :accounts},
      account_transaction_consumptions: %{read: :accounts, create: :accounts, approve: :accounts},
      end_user_transaction_consumptions: %{read: :accounts, create: :accounts, approve: :accounts},
      account_exports: %{read: :accounts, create: :accounts},
      admin_user_exports: :none,
      configuration: :none
    },
    viewer: %{
      account: %{read: :accounts},
      categories: %{read: :global},
      admin_users: %{read: :accounts},
      end_users: %{read: :accounts},
      access_keys: %{read: :accounts},
      api_keys: %{read: :accounts},
      tokens: %{read: :global},
      mints: :none,
      account_wallets: %{read: :global, view_balance: :accounts},
      end_user_wallets: %{read: :global, view_balance: :accounts},
      account_transactions: %{read: :accounts},
      end_user_transactions: %{read: :accounts},
      account_transaction_requests: %{read: :accounts},
      end_user_transaction_requests: %{read: :accounts},
      account_transaction_consumptions: %{read: :accounts},
      end_user_transaction_consumptions: %{read: :accounts},
      account_exports: %{read: :accounts},
      admin_user_exports: :none,
      configuration: :none
    }
  }

  schema "role" do
    external_id(prefix: "rol_")

    field(:name, :string)
    field(:priority, :integer)
    field(:display_name, :string)

    many_to_many(
      :users,
      User,
      join_through: Membership,
      join_keys: [role_uuid: :uuid, user_uuid: :uuid]
    )

    timestamps()
    soft_delete()
    activity_logging()
  end

  def account_role_permissions, do: @account_role_permissions

  defp changeset(%Role{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:priority, :name, :display_name],
      required: [:name, :priority]
    )
    |> validate_required([:name, :priority])
    |> unique_constraint(:name)
    |> unique_constraint(:priority)
  end

  @doc """
  Get all roles.
  """
  @spec all(keyword()) :: [%__MODULE__{}] | []
  def all(opts \\ []) do
    __MODULE__
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves a role with the given ID.
  """
  @spec get(String.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves a role using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new role with the passed attributes.
  """
  def insert(attrs) do
    highest_priority = Repo.one(from(r in Role, select: max(r.priority)))

    [{key, _}] = Enum.take(attrs, 1)
    priority_field = if is_atom(key), do: :priority, else: "priority"

    attrs =
      case highest_priority do
        nil ->
          Map.put(attrs, priority_field, 0)

        highest_priority ->
          Map.put(attrs, priority_field, highest_priority + 1)
      end

    %Role{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Updates a role with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(role, attrs) do
    role
    |> changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Checks whether the given role is soft-deleted.
  """
  @spec deleted?(%__MODULE__{}) :: boolean()
  def deleted?(role), do: SoftDelete.deleted?(role)

  @doc """
  Soft-deletes the given role. The operation fails if the role
  has one more more users associated.
  """
  @spec delete(%__MODULE__{}, map()) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def delete(role, originator) do
    empty? =
      role
      |> Repo.preload(:users)
      |> Map.get(:users)
      |> Enum.empty?()

    case empty? do
      true -> SoftDelete.delete(role, originator)
      false -> {:error, :role_not_empty}
    end
  end

  @doc """
  Restores the given role from soft-delete.
  """
  @spec restore(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def restore(role, originator), do: SoftDelete.restore(role, originator)

  @doc """
  Compares that the given string value is equivalent to the given role.
  """
  def is_role?(%Role{} = role, role_name) do
    role.name == role_name
  end
end
