# Copyright 2018-2019 OmiseGO Pte Ltd
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
  import Ecto.Changeset
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Membership, Repo, Role, User}

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]
  @account_role_permissions %{
    "admin" => %{
      accounts: %{all: :accounts, get: :accounts, update: :accounts},
      categories: %{all: :global, get: :global},
      memberships: %{all: :accounts, get: :accounts, create: :accounts, delete: :accounts},
      admin_users: %{
        all: :accounts,
        get: :accounts,
        create: :accounts,
        update: :accounts,
        update_password: :self,
        update_email: :self,
        upload_avatar: :self,
        get_account: :self,
        get_accounts: :self,
        logout: :self
      },
      end_users: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        update: :accounts,
        login: :accounts,
        logout: :accounts
      },
      access_keys: %{
        all: :accounts,
        get: :accounts,
        create: :accounts,
        update: :accounts,
        disable: :accounts
      },
      api_keys: %{
        all: :accounts,
        get: :accounts,
        create: :accounts,
        update: :accounts,
        disable: :accounts
      },
      tokens: %{all: :global, get: :global},
      mints: :none,
      account_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :accounts,
        update: :accounts
      },
      end_user_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :accounts,
        update: :accounts
      },
      account_transactions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      end_user_transactions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      account_transaction_requests: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        confirm: :accounts
      },
      end_user_transaction_requests: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        confirm: :accounts
      },
      account_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        cancel: :accounts
      },
      end_user_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        cancel: :accounts
      },
      exports: :none,
      configuration: :none
    },
    "viewer" => %{
      account: %{all: :accounts, get: :accounts},
      categories: %{all: :global, get: :global},
      memberships: %{all: :accounts, get: :accounts},
      admin_users: %{
        all: :accounts,
        get: :accounts,
        get_account: :self,
        get_accounts: :self,
        logout: :self
      },
      end_users: %{all: :accounts, get: :accounts, listen: :accounts},
      access_keys: %{all: :accounts, get: :accounts},
      api_keys: %{all: :accounts, get: :accounts},
      tokens: %{all: :global, get: :global},
      mints: :none,
      account_wallets: %{all: :global, get: :global, listen: :accounts, view_balance: :accounts},
      end_user_wallets: %{all: :global, get: :global, listen: :accounts, view_balance: :accounts},
      account_transactions: %{all: :accounts, get: :accounts, listen: :accounts},
      end_user_transactions: %{all: :accounts, get: :accounts, listen: :accounts},
      account_transaction_requests: %{all: :accounts, get: :accounts, listen: :accounts},
      end_user_transaction_requests: %{all: :accounts, get: :accounts, listen: :accounts},
      account_transaction_consumptions: %{all: :accounts, get: :accounts, listen: :accounts},
      end_user_transaction_consumptions: %{all: :accounts, get: :accounts, listen: :accounts},
      exports: :none,
      configuration: :none
    }
  }

  schema "role" do
    external_id(prefix: "rol_")

    field(:name, :string)
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

  def account_roles, do: Map.keys(@account_role_permissions)
  def account_role_permissions, do: @account_role_permissions

  defp changeset(%Role{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :display_name],
      required: [:name]
    )
    |> validate_required([:name])
    |> validate_inclusion(:name, account_roles())
    |> unique_constraint(:name, name: "role_name_index")
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

  def insert_default_roles(originator) do
    Enum.each(account_roles(), fn role ->
      {:ok, _} =
        insert(%{
          name: role,
          display_name: String.capitalize(role),
          originator: originator
        })
    end)

    :ok
  end
end
