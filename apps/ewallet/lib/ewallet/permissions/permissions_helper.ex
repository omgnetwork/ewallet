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

defmodule EWallet.PermissionsHelper do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWallet.SchemaPermissions.{
    AccountPermissions,
    CategoryPermissions,
    KeyPermissions,
    TransactionRequestPermissions,
    TransactionConsumptionPermissions,
    UserPermissions,
    WalletPermissions
  }

  alias EWalletDB.{
    Account,
    User,
    Category,
    Key,
    Wallet,
    TransactionRequest,
    TransactionConsumption
  }

  @references %{
    Account => AccountPermissions,
    Category => CategoryPermissions,
    Key => KeyPermissions,
    TransactionRequest => TransactionRequestPermissions,
    TransactionConsumption => TransactionConsumptionPermissions,
    User => UserPermissions,
    Wallet => WalletPermissions
  }

  # Cleans up dirty inputs into a unified actor representation.
  # Either a key, an admin user or an end user
  def get_actor(%{admin_user: admin_user}), do: admin_user
  def get_actor(%{end_user: end_user}), do: end_user
  def get_actor(%{key: key}), do: key
  def get_actor(%{originator: %{end_user: end_user}}), do: end_user
  def get_actor(_), do: nil

  def get_uuids(list) do
    Enum.map(list, fn account -> account.uuid end)
  end

  # Gets all the owner uuids of the given record.
  # Could be user and/or account uuids.
  def get_owner_uuids(record) do
    @references[record.__struct__].get_owner_uuids(record)
  end

  # Redefines the target type if the given record has subtypes.
  # like transaction_requests -> end_user_transaction_requests /
  # account_transaction_requests.
  def get_target_type(record) do
    @references[record.__struct__].get_target_type(record)
  end

  # Gets all the accounts the actor (a key, an admin user or an end user)
  # has access to.
  def get_actor_accounts(record) do
    @references[record.__struct__].get_actor_accounts(record)
  end

  # Loads all the accounts that have power over the given record.
  def get_target_accounts(record) do
    @references[record.__struct__].get_target_accounts(record)
  end
end
