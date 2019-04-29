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

defmodule EWalletDB.Key do
  @moduledoc """
  Ecto Schema representing key.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias Utils.Helpers.Crypto

  alias EWalletDB.{
    Account,
    Key,
    GlobalRole,
    Membership,
    Role,
    Repo
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  # String length = ceil(key_bytes / 3 * 4)
  @key_bytes 32
  @secret_bytes 128

  schema "key" do
    external_id(prefix: "key_")

    field(:name, :string)
    field(:access_key, :string)
    field(:secret_key, :string, virtual: true)
    field(:secret_key_hash, :string)
    field(:global_role, :string)

    has_many(
      :memberships,
      Membership,
      foreign_key: :key_uuid,
      references: :uuid
    )

    many_to_many(
      :roles,
      Role,
      join_through: Membership,
      join_keys: [key_uuid: :uuid, role_uuid: :uuid]
    )

    many_to_many(
      :accounts,
      Account,
      join_through: Membership,
      join_keys: [key_uuid: :uuid, account_uuid: :uuid]
    )

    field(:enabled, :boolean, default: true)
    timestamps()
    soft_delete()
    activity_logging()
  end

  defp insert_changeset(%Key{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :access_key, :secret_key, :enabled, :global_role],
      required: [:access_key, :secret_key],
      prevent_saving: [:secret_key]
    )
    |> validate_inclusion(:global_role, GlobalRole.global_roles())
    |> unique_constraint(:name, name: :key_name_index)
    |> unique_constraint(:access_key, name: :key_access_key_index)
    |> validate_length(:name, count: :bytes, max: 255)
    |> validate_length(:global_role, count: :bytes, max: 255)
    |> put_change(:secret_key_hash, Crypto.hash_secret(attrs[:secret_key]))
    |> put_change(:secret_key, Base.url_encode64(attrs[:secret_key], padding: false))
  end

  defp update_changeset(%Key{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :global_role, :enabled]
    )
    |> validate_length(:name, count: :bytes, max: 255)
    |> validate_length(:global_role, count: :bytes, max: 255)
    |> unique_constraint(:name, name: :key_name_index)
  end

  defp enable_changeset(%Key{} = key, attrs) do
    cast_and_validate_required_for_activity_log(
      key,
      attrs,
      cast: [:enabled],
      required: [:enabled]
    )
  end

  @doc """
  Get all keys, exclude soft-deleted.
  """
  @spec all() :: [%Key{}]
  def all do
    Key
    |> exclude_deleted()
    |> Repo.all()
  end

  def query_all_for_account_uuids(query, account_uuids) do
    query
    |> exclude_deleted()
    |> where([a], a.account_uuid in ^account_uuids)
  end

  @doc """
  Retrieves a key with the given ID.
  """
  @spec get(String.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves a key using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new key with the passed attributes.

  The `account_uuid` defaults to the master account if not provided.
  The `access_key` and `secret_key` are automatically generated if not specified.
  """
  @spec insert(map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:access_key, fn -> Crypto.generate_base64_key(@key_bytes) end)
      |> Map.put_new_lazy(:secret_key, fn -> Crypto.generate_key(@secret_bytes) end)

    %Key{}
    |> insert_changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Updates a key with the provided attributes.
  """
  @spec update(%Key{}, map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  def update(%Key{} = key, attrs) do
    key
    |> update_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Enable or disable a key with the provided attributes.
  """
  @spec enable_or_disable(%Key{}, map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  # This function supports the deprecated "expired" key
  def enable_or_disable(%Key{} = key, %{"expired" => expired} = attrs) do
    attrs = Map.put(attrs, "enabled", !expired)

    key
    |> enable_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @spec enable_or_disable(%Key{}, map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  def enable_or_disable(%Key{} = key, attrs) do
    key
    |> enable_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Authenticates using the specified access and secret keys.
  Returns the key if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the access/secret key information around.
  """
  @spec authenticate(String.t(), String.t()) :: {:ok, %Key{}} | false
  def authenticate(access, secret)
      when is_binary(access) and is_binary(secret) do
    query =
      from(
        k in Key,
        where: k.access_key == ^access and k.enabled == true
      )

    query
    |> Repo.all()
    |> Enum.at(0)
    |> authenticate(secret)
  end

  def authenticate(%{secret_key_hash: secret_key_hash} = key, secret) do
    case Crypto.verify_secret(secret, secret_key_hash) do
      true -> {:ok, key}
      _ -> false
    end
  end

  # Deliberately slow down invalid query to make user enumeration harder.
  #
  # There is still timing leak when the query wasn't called due to either
  # access or secret being nil, but no enumeration could took place in
  # such cases.
  #
  # There is also timing leak due to fake_verify not performing comparison
  # (only performing Bcrypt hash operation) which may be a problem.
  def authenticate(_, _) do
    Crypto.fake_verify()
  end

  @doc """
  Checks whether the given key is soft-deleted.
  """
  @spec deleted?(%Key{}) :: boolean()
  def deleted?(key), do: SoftDelete.deleted?(key)

  @doc """
  Soft-deletes the given key.
  """
  @spec delete(%Key{}, map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  def delete(key, originator), do: SoftDelete.delete(key, originator)

  @doc """
  Restores the given key from soft-delete.
  """
  @spec restore(%Key{}, map()) :: {:ok, %Key{}} | {:error, Ecto.Changeset.t()}
  def restore(key, originator), do: SoftDelete.restore(key, originator)

  @doc """
  Retrieves all account uuids that are accessible by the given key.
  """
  @spec get_all_accessible_account_uuids(%Key{}) :: [String.t()]
  def get_all_accessible_account_uuids(key) do
    [key.account.uuid]
  end
end
