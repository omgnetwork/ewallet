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

defmodule EWallet.BouncerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer
  alias EWallet.Bouncer.{Permission, DispatchConfig}
  alias EWalletDB.{Membership, Wallet}
  alias ActivityLogger.System

  def global_permissions do
    %{
      "super_admin" => :global,
      "end_user" => %{
        account_permissions: false
      },
      "none_with_no_account_permissions" => %{
        account_permissions: false
      },
      "none" => %{
        account_permissions: true
      }
    }
  end

  def account_permissions do
    %{
      "admin" => %{
        account_wallets: %{
          all: :accounts
        }
      }
    }
  end

  describe "bounce/3" do
    test "returns a global authorized permission" do
      actor = insert(:admin, global_role: "super_admin")
      permission = %Permission{action: :all, type: :wallets, schema: Wallet}

      {:ok, permission} =
        Bouncer.bounce(%{admin_user: actor}, permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: global_permissions(),
          account_permissions: account_permissions()
        })

      assert permission.authorized == true
      assert permission.global_authorized == true
      assert permission.global_role == "super_admin"
      assert permission.global_abilities == %{account_wallets: :global, end_user_wallets: :global}
      assert permission.account_authorized == false
      assert permission.account_abilities == %{}
    end

    test "returns an account authorized permission" do
      actor = insert(:admin, global_role: nil)
      account = insert(:account)
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      permission = %Permission{action: :all, type: :wallets, schema: Wallet}

      {:ok, permission} =
        Bouncer.bounce(%{admin_user: actor}, permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: global_permissions(),
          account_permissions: account_permissions()
        })

      assert permission.authorized == true
      assert permission.global_authorized == false
      assert permission.global_role == "none"
      assert permission.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
      assert permission.account_authorized == true

      assert permission.account_abilities == %{
               account_wallets: :accounts,
               end_user_wallets: :none
             }
    end

    test "skips the accounts permission if not allowed" do
      actor = insert(:admin, global_role: "none_with_no_account_permissions")
      account = insert(:account)
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      permission = %Permission{action: :all, type: :wallets, schema: Wallet}

      {:error, permission} =
        Bouncer.bounce(%{admin_user: actor}, permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: global_permissions(),
          account_permissions: account_permissions()
        })

      assert permission.authorized == false
      assert permission.check_account_permissions == false
      assert permission.global_authorized == false
      assert permission.global_role == "none_with_no_account_permissions"
      assert permission.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
      assert permission.account_authorized == false
      assert permission.account_abilities == %{}
    end
  end

  describe "scoped_query/1" do
    test "returns a scoped query" do
      permission = %Permission{
        authorized: true,
        global_abilities: %{account_wallets: :global, end_user_wallets: :global},
        action: :all,
        type: :wallets,
        schema: Wallet
      }

      assert Bouncer.scoped_query(permission) == Wallet
    end
  end
end
