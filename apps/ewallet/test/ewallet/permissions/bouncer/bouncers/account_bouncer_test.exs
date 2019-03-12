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

defmodule EWallet.AccountBouncerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{AccountBouncer, Permission, DispatchConfig}
  alias EWalletDB.{AccountUser, User, Account, Membership, Wallet}
  alias ActivityLogger.System

  def permissions do
    %{
      "admin" => %{
        account_wallets: %{
          all: :accounts,
          export: :accounts,
          get: :accounts,
          create: :none
        },
        end_user_wallets: %{
          all: :accounts,
          export: :accounts,
          get: :accounts,
          create: :none
        }
      }
    }
  end

  describe "bounce/1 with action = all" do
    test "with accounts permission (authorized)" do
      actor = insert(:admin)
      account = insert(:account)
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      permission = %Permission{actor: actor, action: :all, type: :wallets, schema: Wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == true
      assert res.account_abilities == %{account_wallets: :accounts, end_user_wallets: :accounts}
    end

    test "with no permission (unauthorized)" do
      actor = insert(:admin)
      permission = %Permission{actor: actor, action: :all, type: :wallets, schema: Wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == false
      assert res.account_abilities == %{}
    end
  end

  describe "bounce/1 with action = export" do
    test "with accounts permission (authorized)" do
      actor = insert(:admin)
      account = insert(:account)
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      permission = %Permission{actor: actor, action: :export, type: :wallets, schema: Wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == true
      assert res.account_abilities == %{account_wallets: :accounts, end_user_wallets: :accounts}
    end

    test "with no permission (unauthorized)" do
      actor = insert(:admin)
      permission = %Permission{actor: actor, action: :export, type: :wallets, schema: Wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == false
      assert res.account_abilities == %{}
    end
  end

  describe "bounce/1 with action = get" do
    test "with accounts permission and account wallet (authorized)" do
      actor = insert(:admin)
      {:ok, account} = :account |> params_for() |> Account.insert()
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      wallet = Account.get_primary_wallet(account)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == true
      assert res.account_abilities == %{account_wallets: :accounts}
    end

    test "with no permission (unauthorized)" do
      actor = insert(:admin)
      wallet = insert(:wallet)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == false
      assert res.account_abilities == %{}
    end

    test "with accounts permission and end user wallet (authorized)" do
      actor = insert(:admin)
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, _} = Membership.assign(actor, account, "admin", %System{})
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})
      wallet = User.get_primary_wallet(user)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == true
      assert res.account_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and end user wallet (unauthorized)" do
      actor = insert(:admin)
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        AccountBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          account_permissions: permissions()
        })

      assert res.account_authorized == false
      assert res.account_abilities == %{}
    end
  end
end
