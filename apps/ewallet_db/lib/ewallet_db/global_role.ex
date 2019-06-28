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

  # This is an empty struct for the sole purpose of compatibility. So the bouncer can reference
  # this global role by `%GlobalRole{}` like it does with other targets.
  defstruct []

  # global admin -

  @global_role_permissions %{
    "super_admin" => :global,
    "admin" => %{
      account_permissions: true,
      exchange_pairs: %{
        all: :global,
        get: :global
      },
      accounts: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global,
        update: :global
      },
      memberships: %{all: :global, get: :global, create: :global, delete: :global},
      categories: %{all: :global, get: :global, create: :global, update: :global},
      admin_users: %{
        all: :global,
        get: :global,
        update: :self,
        disable: :self,
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
        create: :global,
        update: :global,
        disable: :none,
        login: :global,
        logout: :global
      },
      access_keys: %{
        all: :global,
        get: :global,
        create: :global,
        update: :global,
        disable: :global
      },
      api_keys: %{
        all: :global,
        get: :global,
        create: :global,
        update: :global,
        disable: :global
      },
      tokens: %{all: :global, get: :global, create: :none, update: :none},
      mints: %{all: :none, get: :none, create: :none},
      account_wallets: %{
        all: :global,
        get: :global,
        listen: :global,
        view_balance: :global,
        create: :global,
        update: :global
      },
      end_user_wallets: %{
        all: :global,
        get: :global,
        listen: :global,
        view_balance: :global,
        create: :global,
        update: :global
      },
      blockchain_wallets: %{
        view_balance: :global
      },
      account_transactions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global
      },
      end_user_transactions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global
      },
      account_transaction_requests: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global,
        cancel: :global
      },
      end_user_transaction_requests: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global,
        cancel: :global
      },
      account_transaction_consumptions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global,
        cancel: :global
      },
      end_user_transaction_consumptions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :global,
        cancel: :global
      },
      exports: %{all: :self, get: :self, create: :global},
      configuration: :none,
      permissions: %{all: :global}
    },
    "viewer" => %{
      account_permissions: true,
      exchange_pairs: %{
        all: :global,
        get: :global
      },
      accounts: %{all: :global, get: :global, create: :none, update: :none},
      categories: %{all: :global, get: :global, create: :none, update: :none},
      memberships: %{all: :global, get: :global, create: :none, update: :none},
      admin_users: %{
        all: :global,
        get: :global,
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
        create: :none,
        update: :none,
        disable: :none
      },
      access_keys: %{all: :global, get: :global, create: :none, update: :none, disable: :none},
      api_keys: %{all: :global, get: :global, create: :none, update: :none, disable: :none},
      tokens: %{all: :global, get: :global, create: :none, update: :none},
      mints: %{all: :none, get: :none, create: :none},
      account_wallets: %{
        all: :global,
        get: :global,
        listen: :global,
        view_balance: :global,
        create: :none,
        update: :none
      },
      end_user_wallets: %{
        all: :global,
        get: :global,
        listen: :global,
        view_balance: :global,
        create: :none,
        update: :none
      },
      blockchain_wallets: %{
        view_balance: :global
      },
      account_transactions: %{all: :global, listen: :global, get: :global, create: :none},
      end_user_transactions: %{all: :global, listen: :global, get: :global, create: :none},
      account_transaction_requests: %{
        all: :global,
        listen: :global,
        get: :global,
        create: :none,
        cancel: :none
      },
      end_user_transaction_requests: %{
        all: :global,
        listen: :global,
        get: :global,
        create: :none,
        cancel: :none
      },
      account_transaction_consumptions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :none,
        approve: :none,
        cancel: :none
      },
      end_user_transaction_consumptions: %{
        all: :global,
        get: :global,
        listen: :global,
        create: :none,
        approve: :none,
        cancel: :none
      },
      exports: %{all: :self, get: :self, create: :none},
      configuration: :none,
      permissions: %{all: :global}
    },
    "end_user" => %{
      account_permissions: false,
      exchange_pairs: %{
        all: :global,
        get: :global
      },
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
        confirm: :self,
        cancel: :self
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
