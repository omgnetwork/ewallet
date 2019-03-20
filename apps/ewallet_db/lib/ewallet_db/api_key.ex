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

defmodule EWalletDB.APIKey do
  @moduledoc """
  Ecto Schema representing API key.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  import EWalletConfig.Validator
  import EWalletDB.Helpers.Preloader
  alias ActivityLogger.System
  alias Ecto.UUID
  alias EWalletDB.{Key, Repo, Seeder, User}
  alias Utils.Helpers.Crypto

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  # String length = ceil(key_bytes / 3 * 4)
  @key_bytes 32

  schema "api_key" do
    external_id(prefix: "api_")

    field(:name, :string)
    field(:key, :string)

    belongs_to(
      :creator_user,
      User,
      foreign_key: :creator_user_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :creator_key,
      Key,
      foreign_key: :creator_key_uuid,
      references: :uuid,
      type: UUID
    )

    field(:enabled, :boolean, default: true)
    timestamps()
    soft_delete()
    activity_logging()
  end

  defp changeset(%__MODULE__{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :key, :creator_user_uuid, :creator_key_uuid, :enabled],
      required: [:key]
    )
    |> validate_exclusive([:creator_user_uuid, :creator_key_uuid])
    |> unique_constraint(:key)
    |> assoc_constraint(:creator_user)
    |> assoc_constraint(:creator_key)
  end

  defp enable_changeset(%__MODULE__{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:enabled],
      required: [:enabled]
    )
  end

  defp update_changeset(%__MODULE__{} = key, attrs) do
    key
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:name, :enabled],
      required: [:enabled]
    )
  end

  @doc """
  Build the query for all APIKeys excluding the soft-deleted ones.
  """
  def query_all do
    __MODULE__
    |> exclude_deleted()
  end

  @doc """
  Get an API key by id, exclude soft-deleted.
  """
  @spec get(String.t()) :: %__MODULE__{} | nil
  def get(id) when is_external_id(id) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(id: id)
  end

  def get(_), do: nil

  @doc """
  Get an API key by a specific field, exclude soft-deleted.
  """
  @spec get_by(Keyword.t()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new API key with the passed attributes.

  The key is automatically generated if not specified.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    attrs =
      attrs
      |> Map.put_new_lazy(:key, fn -> Crypto.generate_base64_key(@key_bytes) end)
      |> populate_creator()

    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log()
  end

  defp populate_creator(%{creator_user_uuid: _} = attrs), do: attrs

  defp populate_creator(%{creator_key_uuid: _} = attrs), do: attrs

  defp populate_creator(%{originator: %User{uuid: uuid}} = attrs) do
    Map.put(attrs, :creator_user_uuid, uuid)
  end

  defp populate_creator(%{originator: %Key{uuid: uuid}} = attrs) do
    Map.put(attrs, :creator_key_uuid, uuid)
  end

  defp populate_creator(%{originator: %System{}} = attrs), do: attrs

  defp populate_creator(%{originator: %Seeder{}} = attrs), do: attrs

  @doc """
  Updates an API key with the provided attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(api_key, attrs) do
    attrs = populate_enabled(attrs)

    api_key
    |> update_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  defp populate_enabled(%{"expired" => expired} = attrs), do: Map.put(attrs, "enabled", !expired)

  defp populate_enabled(attrs), do: attrs

  @doc """
  Enable or disable an API key with the provided attributes.
  """
  @spec enable_or_disable(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def enable_or_disable(api_key, attrs) do
    api_key
    |> enable_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Authenticates using the given API key id and its key.
  Returns the associated account if authenticated, false otherwise.

  Use this function instead of the usual get/2
  to avoid passing the API key information around.
  """
  def authenticate(api_key_id, api_key)
      when byte_size(api_key_id) > 0 and byte_size(api_key) > 0 do
    api_key_id
    |> get()
    |> do_authenticate(api_key)
  end

  def authenticate(_, _), do: Crypto.fake_verify()

  defp do_authenticate(%{key: expected_key} = api_key, input_key) do
    case Crypto.secure_compare(expected_key, input_key) do
      true -> api_key
      _ -> false
    end
  end

  defp do_authenticate(nil, _input_key), do: Crypto.fake_verify()

  @doc """
  Authenticates using the given API key (without API key id).
  Returns the associated account if authenticated, false otherwise.

  Note that this is not protected against timing attacks
  and should only be used for non-sensitive requests, e.g. read-only requests.
  """
  def authenticate(nil), do: false

  def authenticate(api_key) do
    case get_by(key: api_key) do
      %__MODULE__{} = api_key -> api_key
      nil -> false
    end
  end

  @doc """
  Checks whether the given API key is soft-deleted.
  """
  def deleted?(api_key), do: SoftDelete.deleted?(api_key)

  @doc """
  Soft-deletes the given API key.
  """
  def delete(api_key, originator), do: SoftDelete.delete(api_key, originator)

  @doc """
  Restores the given API key from soft-delete.
  """
  def restore(api_key, originator), do: SoftDelete.restore(api_key, originator)
end
