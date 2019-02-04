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

defmodule EWallet.SchemaPermissions.WalletPermissions do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWalletDB.Wallet

  def get_target_accounts(%Wallet{account_uuid: nil} = target) do
    get_target_accounts(target.user)
  end

  # account wallets
  def get_target_accounts(%Wallet{user_uuid: nil} = target) do
    [target.account]
  end
end
