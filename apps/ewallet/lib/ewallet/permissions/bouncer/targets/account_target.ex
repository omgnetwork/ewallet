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

defmodule EWallet.Bouncer.AccountTarget do
  @moduledoc """
  The target handler for accounts.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.{Account, Helpers.Preloader}

  @spec get_owner_uuids(Account.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(account) do
    memberships = Preloader.preload(account, [:memberships]).memberships

    Enum.map(memberships, fn membership ->
      membership.user_uuid || membership.key_uuid
    end)
  end

  @spec get_target_types() :: [:accounts]
  def get_target_types, do: [:accounts]

  @spec get_target_type() :: :accounts
  def get_target_type, do: :accounts

  @spec get_target_accounts(Account.t(), any()) :: [Account.t()]
  def get_target_accounts(%Account{} = target, _) do
    [target]
  end
end
