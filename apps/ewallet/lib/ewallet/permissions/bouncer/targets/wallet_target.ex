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

defmodule EWallet.Bouncer.WalletTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWallet.Bouncer.Dispatcher
  alias EWalletDB.{Wallet, Helpers.Preloader}

  def get_owner_uuids(%Wallet{account_uuid: account_uuid})
      when not is_nil(account_uuid) do
    [account_uuid]
  end

  def get_owner_uuids(%Wallet{user_uuid: user_uuid})
      when not is_nil(user_uuid) do
    [user_uuid]
  end

  def get_target_types do
    [:account_wallets, :end_user_wallets]
  end

  def get_target_type(%Wallet{account_uuid: account_uuid})
      when not is_nil(account_uuid) do
    :account_wallets
  end

  def get_target_type(%Wallet{user_uuid: user_uuid})
      when not is_nil(user_uuid) do
    :end_user_wallets
  end

  def get_target_accounts(%Wallet{account_uuid: nil} = target, dispatch_config) do
    user = Preloader.preload(target, [:user]).user
    Dispatcher.get_target_accounts(user, dispatch_config)
  end

  # account wallets
  def get_target_accounts(%Wallet{user_uuid: nil} = target, _dispatch_config) do
    account = Preloader.preload(target, [:account]).account
    [account]
  end
end
