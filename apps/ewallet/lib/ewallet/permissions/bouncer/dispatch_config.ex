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

defmodule EWallet.Bouncer.DispatchConfig do
  @moduledoc """
  A permissions dispatcher calling the appropriate actors/targets.
  """
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
    ConfigurationTarget,
    UserActor,
    TransactionScope,
    TransactionConsumptionScope,
    TransactionRequestScope,
    WalletScope,
    AccountScope,
    ActivityLogScope,
    ExchangePairScope,
    KeyScope,
    UserScope,
    CategoryScope,
    TokenScope,
    ConfigurationScope
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

  alias EWalletConfig.Setting

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
    Setting => ConfigurationScope
  }

  @actor_references %{
    User => UserActor,
    Key => KeyActor
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
    ActivityLog => ActivityLogTarget,
    Setting => ConfigurationTarget
  }

  def scope_references, do: @scope_references
  def actor_references, do: @actor_references
  def target_references, do: @target_references
end
