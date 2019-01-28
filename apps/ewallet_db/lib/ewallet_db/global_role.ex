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

defmodule EWalletDB.GlobalRole do
  @moduledoc """
  Fake Schema representing global roles.
  """

  @global_roles %{
    super_admin: :global,
    admin: %{
      accounts: %{read: :accounts, create: :none, update: :accounts},
      categories: %{read: :global, create: :none, update: :none},
      admin_users: %{read: :accounts, create: :accounts, update: :accounts, disable: :accounts},
      end_users: %{read: :global, create: :accounts, update: :accounts, disable: :none},
      access_keys: %{read: :accounts, create: :accounts, update: :accounts, disable: :accounts},
      api_keys: %{read: :accounts, create: :accounts, update: :accounts, disable: :accounts},
      tokens: %{read: :global, create: :none, update: :none},
      mints: %{read: :none, create: :none},
      account_wallets: %{read: :global, view_balance: :accounts, create: :accounts, update: :accounts},
      end_user_wallets: %{read: :global, view_balance: :accounts, create: :accounts, update: :accounts},
      account_transactions: %{read: :accounts, create: :accounts},
      end_user_transactions: %{read: :accounts, create: :accounts},
      account_transaction_requests: %{read: :accounts, create: :accounts},
      end_user_transaction_requests: %{read: :accounts, create: :accounts},
      account_transaction_consumptions: %{read: :accounts, create: :accounts, approve: :accounts},
      end_user_transaction_consumptions: %{read: :accounts, create: :accounts, approve: :accounts},
      account_exports: %{read: :accounts, create: :accounts},
      admin_user_exports: %{read: :admin_user, create: :admin_user},
      configuration: :none
    },
    viewer: %{
      accounts: %{read: :accounts, create: :none, update: :none},
      categories: %{read: :global, create: :none, update: :none},
      admin_users: %{read: :accounts, create: :none, update: :none, disable: :none},
      end_users: %{read: :global, create: :none, update: :none, disable: :none},
      access_keys: %{read: :accounts, create: :none, update: :none, disable: :none},
      api_keys: %{read: :accounts, create: :none, update: :none, disable: :none},
      tokens: %{read: :global, create: :none, update: :none},
      mints: %{read: :none, create: :none},
      account_wallets: %{read: :global, view_balance: :accounts, create: :none, update: :none},
      end_user_wallets: %{read: :global, view_balance: :accounts, create: :none, update: :none},
      account_transactions: %{read: :accounts, create: :none},
      end_user_transactions: %{read: :accounts, create: :none},
      account_transaction_requests: %{read: :accounts, create: :none},
      end_user_transaction_requests: %{read: :accounts, create: :none},
      account_transaction_consumptions: %{read: :accounts, create: :none, approve: :none},
      end_user_transaction_consumptions: %{read: :accounts, create: :none, approve: :none},
      account_exports: %{read: :accounts, create: :none},
      admin_user_exports: %{read: :admin_user, create: :none},
      configuration: :none
    },
    none: :none
  }

  def global_roles, do: @global_roles
end
