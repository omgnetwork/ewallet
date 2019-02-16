# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.AccountUser do
  @moduledoc """
  Ecto Schema representing the relation between an account and a user.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  use ActivityLogger.ActivityLogging
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{Account, AccountUser, User}
  alias EWalletDB.Repo

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "account_user" do
    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
    activity_logging()
  end

  @spec changeset(account :: %AccountUser{}, attrs :: map()) :: Ecto.Changeset.t()
  defp changeset(%AccountUser{} = account, attrs) do
    account
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:account_uuid, :user_uuid],
      required: [:account_uuid, :user_uuid]
    )
    |> unique_constraint(:account_uuid, name: :account_user_account_uuid_user_uuid_index)
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
  end

  @spec insert(attrs :: map()) :: {:ok, %AccountUser{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    opts = [on_conflict: :nothing]

    %AccountUser{}
    |> changeset(attrs)
    |> Repo.insert_record_with_activity_log(opts)
  end

  def link(account_uuid, user_uuid, originator) do
    insert(%{
      account_uuid: account_uuid,
      user_uuid: user_uuid,
      originator: originator
    })
  end
end
