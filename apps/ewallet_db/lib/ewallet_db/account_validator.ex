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

defmodule EWalletDB.AccountValidator do
  @moduledoc """
  Specific validators for `EWalletDB.Account`.
  """
  import Ecto.Changeset
  alias EWalletDB.Account

  @doc """
  Validates that there can be only one master account in the system.
  """
  @spec validate_parent_uuid(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_parent_uuid(changeset) do
    # Require a `parent_uuid` if:
    #   1. This changeset has `parent_uuid` == nil
    #   2. The master account already exists
    #   3. This changeset is not for the master account
    with nil <- get_field(changeset, :parent_uuid),
         %{} = master <- Account.get_master_account(),
         false <- master.uuid == get_field(changeset, :uuid) do
      validate_required(changeset, :parent_uuid)
    else
      _ -> changeset
    end
  end

  @doc """
  Validates that the given account is still within the given number of child levels
  relative to the master account.

  This validator makes a DB call to find out the child level of the given parent account.

  `child_level_limit` values:
    - `0` : valid if the account is the master account
    - `1` : valid if the account is the master account or its direct children
    - `2` : valid if the account is the master account, its direct children, or one more level down
    - ...
  """
  @spec validate_account_level(Ecto.Changeset.t(), non_neg_integer()) :: Ecto.Changeset.t()
  def validate_account_level(changeset, child_level_limit) do
    if get_depth(changeset) > child_level_limit do
      add_error(
        changeset,
        :parent_uuid,
        "is at the maximum child level",
        validation: :account_level_limit
      )
    else
      changeset
    end
  end

  defp get_depth(changeset) do
    case fetch_field(changeset, :parent_uuid) do
      {_, nil} ->
        # If the account does not have a parent_uuid,
        # it means it's a top-level account
        0

      {_, parent_uuid} ->
        # Since the depth returned is of the parent,
        # we need to +1 to get this account's depth
        Account.get_depth(parent_uuid) + 1
    end
  end
end
