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

defmodule EWallet.WalletPolicy do
  @moduledoc """
  The authorization policy for wallets.
  """
  alias EWallet.{PolicyHelper, Bouncer, Bouncer.Permission}
  alias EWalletDB.Wallet

  def authorize(:create, actor, %{"account_uuid" => account_uuid})
      when not is_nil(account_uuid) do
    Bouncer.bounce(actor, %Permission{
      action: :create,
      target: %Wallet{account_uuid: account_uuid}
    })
  end

  def authorize(:create, actor, %{"user_uuid" => user_uuid}) when not is_nil(user_uuid) do
    Bouncer.bounce(actor, %Permission{action: :create, target: %Wallet{user_uuid: user_uuid}})
  end

  def authorize(:create, _actor, _wallet_attrs) do
    {:error, :unauthorized}
  end

  def authorize(action, actor, target) do
    PolicyHelper.authorize(action, actor, :wallets, Wallet, target)
  end
end
