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

defmodule EWallet.Bouncer.WalletScope do
  @moduledoc """
  A module containing the
  """
  @behaviour EWallet.Bouncer.ScopeBehaviour
  alias EWallet.Bouncer.{Permission, Dispatcher}

  # Global permissions

  # Global + ?
  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: :global}}) do
    Wallet
  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: :accounts}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: :self}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :global, user_wallets: _}}) do

  end

  # Accounts + ?
  def scoped_query(%Permission{global_abilities: %{account_wallets: :accounts, user_wallets: :global}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :accounts, user_wallets: :accounts}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :accounts, user_wallets: :self}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :accounts, user_wallets: _}}) do

  end

  # self + ?
  def scoped_query(%Permission{global_abilities: %{account_wallets: :self, user_wallets: :global}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :self, user_wallets: :accounts}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :self, user_wallets: :self}}) do

  end

  def scoped_query(%Permission{global_abilities: %{account_wallets: :self, user_wallets: _}}) do

  end

  # ---

    # Account permissions

  %{
    "123" => %{
      account_wallets: :global,
      user_wallets: :none
    },
    "345" => %{
      account_wallets: :accounts,
      user_wallets: :accounts
    }
  }
  def scoped_query(%Permission{account_abilities: account_abilities}) do
    Enum.map(account_abilities, fn {account_uuid, abilities} ->
      Enum.map(abilities, fn {type, ability} ->

      end)
    end)
  end


  def scoped_query(permission) do
    Dispatcher.get_query_actor_records(permission)
  end
end
