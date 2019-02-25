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

defmodule EWallet.Bouncer.Dispatcher do
  @moduledoc """
  A permissions dispatcher calling the appropriate actors/targets.
  """
  alias EWallet.Bouncer.Permission

  alias EWallet.Bouncer.{
    AccountTarget,
    CategoryTarget,
    KeyTarget,
    TransactionTarget,
    TransactionRequestTarget,
    MembershipTarget,
    TransactionConsumptionTarget,
    UserTarget,
    ExportTarget,
    WalletTarget,
    MintTarget,
    TokenTarget,
    ActivityLogTarget,
    ExchangePairTarget,
    TransactionScope,
    TransactionConsumptionScope,
    TransactionRequestScope,
    WalletScope,
    AccountScope,
    ActivityLogScope,
    ExchangePairScope,
    CategoryScope,
    KeyScope,
    UserScope
  }

  alias EWalletDB.{
    Account,
    User,
    Category,
    Export,
    Key,
    Membership,
    Wallet,
    Transaction,
    TransactionRequest,
    TransactionConsumption,
    Mint,
    Token,
    ExchangePair
  }

  alias ActivityLogger.ActivityLog

  @scope_references %{
    Account => AccountScope,
    ActivityLog => ActivityLogScope,
    Category => CategoryScope,
    ExchangePair => ExchangePairScope,
    Key => KeyScope,
    Membership => MembershipScope,
    Transaction => TransactionScope,
    TransactionRequest => TransactionRequestScope,
    TransactionConsumption => TransactionConsumptionScope,
    User => UserScope,
    Wallet => WalletScope,
    Mint => MintScope,
    Token => TokenScope,
    Key => KeyScope
  }

  @target_references %{
    Account => AccountTarget,
    Category => CategoryTarget,
    Key => KeyTarget,
    Membership => MembershipTarget,
    ExchangePair => ExchangePairTarget,
    Transaction => TransactionTarget,
    TransactionRequest => TransactionRequestTarget,
    TransactionConsumption => TransactionConsumptionTarget,
    User => UserTarget,
    Wallet => WalletTarget,
    Export => ExportTarget,
    Mint => MintTarget,
    Token => TokenTarget,
    ActivityLog => ActivityLogTarget
  }

  def scoped_query(%Permission{schema: schema} = permission) do
    @scope_references[schema].scoped_query(permission)
  end

  # Gets all the owner uuids of the given record.
  # Could be user and/or account uuids.
  def get_owner_uuids(record) do
    @target_references[record.__struct__].get_owner_uuids(record)
  end

  def authorize_with_attrs(%{schema: schema} = permission) do
    @target_references[schema].authorize_with_attrs(permission)
  end

  # Redefines the target type if the given record has subtypes.
  # like transaction_requests -> end_user_transaction_requests /
  # account_transaction_requests.
  def get_target_types(schema) do
    @target_references[schema].get_target_types()
  end

  def get_target_type(record) do
    @target_references[record.__struct__].get_target_type(record)
  end

  # Returns a query to get all the accounts the actor (a key, an admin user
  # or an end user) has access to
  def get_query_actor_records(%Permission{actor: actor} = permission) do
    @target_references[actor.__struct__].get_query_actor_records(permission)
  end

  # Gets all the accounts the actor (a key, an admin user or an end user)
  # has access to.
  @spec get_actor_accounts(atom() | %{__struct__: any()}) :: any()
  def get_actor_accounts(record) do
    @target_references[record.__struct__].get_actor_accounts(record)
  end

  # Loads all the accounts that have power over the given record.
  def get_target_accounts(record) do
    @target_references[record.__struct__].get_target_accounts(record)
  end
end
