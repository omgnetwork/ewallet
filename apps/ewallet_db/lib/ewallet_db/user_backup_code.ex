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

defmodule EWalletDB.UserBackupCode do
  @moduledoc """
  Ecto Schema representing the backup codes of the user.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Ecto.UUID
  alias Ecto.Multi
  alias EWalletDB.{User, UserBackupCode, Repo}
  alias Utils.Helpers.Crypto

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "user_backup_code" do
    field(:backup_code, :string, virtual: true)
    field(:hashed_backup_code, :string)
    field(:used_at, :naive_datetime_usec)

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  defp changeset(%UserBackupCode{} = user_backup_code, attrs) do
    user_backup_code
    |> cast(attrs, [:backup_code, :user_uuid, :used_at])
    |> validate_required([:backup_code, :user_uuid])
    |> unique_constraint(:user_backup_code)
    |> assoc_constraint(:user)
    |> put_change(:hashed_backup_code, Crypto.hash_secret(attrs[:backup_code]))
  end

  @doc """
  Insert multiple user_backup_code within a single transaction by breaks the backup_codes into multiple record.
  """
  def insert_multiple(%{user_uuid: nil}), do: {:error, :invalid_parameter}

  def insert_multiple(%{backup_codes: backup_codes} = attrs) when is_list(backup_codes) do
    attrs
    |> build_multiple_attrs()
    |> map_changeset()
    |> do_insert()
  end

  defp do_insert(changesets) when is_list(changesets) do
    changesets
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {changeset, index}, acc ->
      Multi.insert(acc, :"insert_user_backup_code_#{index}", changeset)
    end)
    |> Repo.transaction()
  end

  defp build_multiple_attrs(attrs) do
    Enum.map(attrs.backup_codes, fn backup_code ->
      %{
        backup_code: backup_code,
        user_uuid: attrs.user_uuid,
        used_at: nil
      }
    end)
  end

  defp map_changeset(multiple_attrs) when is_list(multiple_attrs) do
    Enum.map(multiple_attrs, fn attrs ->
      changeset(%UserBackupCode{}, attrs)
    end)
  end

  @doc """
  Get all hashed_backup_codes for the given user.

  Optionally, valid is used for specify whether to exclude the invalid hashed_backup_code (which has been used).
  """
  def all_for_user(%User{uuid: uuid}), do: all_for_user(uuid)

  def all_for_user(user_uuid) do
    Repo.all(
      from(
        a in UserBackupCode,
        where: a.user_uuid == ^user_uuid
      )
    )
  end

  @doc """
  Delete the user_backup_code for given user_uuid.
  """
  def delete_for_user(%User{} = user), do: delete_for_user(user.uuid)

  def delete_for_user(user_uuid) do
    Repo.delete_all(
      from(
        a in UserBackupCode,
        where: a.user_uuid == ^user_uuid
      )
    )

    :ok
  end

  defp invalidate_changeset(user_backup_code) do
    user_backup_code
    |> cast(
      %{used_at: NaiveDateTime.utc_now()},
      [:used_at]
    )
    |> validate_required([:used_at])
  end

  @doc """
  Invalidate the given user_backup_code by set field `used_at` to now.
  """
  def invalidate(%UserBackupCode{} = user_backup_code) do
    user_backup_code
    |> invalidate_changeset()
    |> Repo.insert_or_update()
  end
end
