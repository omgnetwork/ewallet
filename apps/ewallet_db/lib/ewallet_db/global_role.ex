# Copyright 2018-2019 OmiseGO Pte Ltd
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

  # global admin -

  @global_role_permissions %{
    "super_admin" => :global,
    "admin" => %{
      account_permissions: true,
      accounts: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :none,
        update: :accounts
      },
      memberships: %{all: :accounts, get: :accounts, create: :accounts, delete: :accounts},
      categories: %{all: :global, get: :global, create: :none, update: :none},
      admin_users: %{
        all: :accounts,
        get: :accounts,
        update: :accounts,
        disable: :accounts,
        update_password: :self,
        update_email: :self,
        upload_avatar: :self,
        get_account: :self,
        get_accounts: :self,
        logout: :self
      },
      end_users: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :accounts,
        update: :accounts,
        disable: :none,
        login: :accounts,
        logout: :accounts
      },
      access_keys: %{
        all: :accounts,
        get: :accounts,
        create: :accounts,
        update: :accounts,
        disable: :accounts
      },
      api_keys: %{
        all: :accounts,
        get: :accounts,
        create: :accounts,
        update: :accounts,
        disable: :accounts
      },
      tokens: %{all: :global, get: :global, create: :none, update: :none},
      mints: %{all: :none, get: :none, create: :none},
      account_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :accounts,
        update: :accounts
      },
      end_user_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :accounts,
        update: :accounts
      },
      account_transactions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      end_user_transactions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      account_transaction_requests: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      end_user_transaction_requests: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts
      },
      account_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        cancel: :accounts
      },
      end_user_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :accounts,
        cancel: :accounts
      },
      exports: %{all: :self, get: :self, create: :global},
      configuration: :none
    },
    "viewer" => %{
      account_permissions: true,
      accounts: %{all: :accounts, get: :accounts, create: :none, update: :none},
      categories: %{all: :global, get: :global, create: :none, update: :none},
      memberships: %{all: :accounts, get: :accounts, create: :none, update: :none},
      admin_users: %{
        all: :accounts,
        get: :accounts,
        create: :none,
        update: :none,
        disable: :none,
        get_account: :self,
        get_accounts: :self,
        logout: :self
      },
      end_users: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :none,
        update: :none,
        disable: :none
      },
      access_keys: %{all: :accounts, get: :accounts, create: :none, update: :none, disable: :none},
      api_keys: %{all: :accounts, get: :accounts, create: :none, update: :none, disable: :none},
      tokens: %{all: :global, get: :global, create: :none, update: :none},
      mints: %{all: :none, get: :none, create: :none},
      account_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :none,
        update: :none
      },
      end_user_wallets: %{
        all: :global,
        get: :global,
        listen: :accounts,
        view_balance: :accounts,
        create: :none,
        update: :none
      },
      account_transactions: %{all: :accounts, listen: :accounts, get: :accounts, create: :none},
      end_user_transactions: %{all: :accounts, listen: :accounts, get: :accounts, create: :none},
      account_transaction_requests: %{
        all: :accounts,
        listen: :accounts,
        get: :accounts,
        create: :none
      },
      end_user_transaction_requests: %{
        all: :accounts,
        listen: :accounts,
        get: :accounts,
        create: :none
      },
      account_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :none,
        approve: :none,
        cancel: :none
      },
      end_user_transaction_consumptions: %{
        all: :accounts,
        get: :accounts,
        listen: :accounts,
        create: :none,
        approve: :none,
        cancel: :none
      },
      exports: %{all: :self, get: :self, create: :none},
      configuration: :none
    },
    "end_user" => %{
      account_permissions: false,
      end_users: %{all: :self, get: :self, listen: :self, update: :self},
      tokens: %{all: :global, get: :global, create: :none, update: :none},
      account_wallets: %{
        all: :none,
        get: :none,
        view_balance: :none,
        create: :none,
        update: :none
      },
      end_user_wallets: %{
        all: :self,
        get: :self,
        listen: :self,
        view_balance: :self,
        create: :self,
        update: :self
      },
      end_user_transactions: %{all: :self, get: :self, listen: :self, create: :self},
      end_user_transaction_requests: %{
        all: :self,
        get: :global,
        listen: :self,
        create: :self,
        confirm: :self
      },
      account_transaction_requests: %{
        get: :global
      },
      end_user_transaction_consumptions: %{
        all: :self,
        get: :self,
        listen: :self,
        create: :self,
        cancel: :self
      }
    },
    "none" => %{
      account_permissions: true
    }
  }

  def super_admin, do: "super_admin"
  def admin, do: "admin"
  def viewer, do: "viewer"
  def end_user, do: "end_user"
  def none, do: "none"
  def global_roles, do: Map.keys(@global_role_permissions)
  def global_role_permissions, do: @global_role_permissions
end
