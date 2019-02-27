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

defmodule EWallet.GlobalBouncerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{GlobalBouncer, Permission, DispatchConfig}
  alias EWalletDB.{AccountUser, User, Account, Membership, Wallet}
  alias ActivityLogger.System

  def permissions do
    %{
      "super_admin" => :global,
      "admin" => %{
        account_wallets: %{
          all: :accounts,
          export: :accounts,
          get: :accounts,
          create: :accounts,
          update: :accounts
        },
        end_user_wallets: %{
          all: :accounts,
          export: :accounts,
          get: :accounts,
          create: :accounts,
          update: :accounts
        },
        account_permissions: true
      },
      "end_user" => %{
        account_wallets: %{all: :none, export: :none, get: :none, create: :none, update: :none},
        end_user_wallets: %{all: :self, export: :self, get: :self, create: :self, update: :self},
        account_permissions: false
      },
      "none" => %{
        account_permissions: true
      }
    }
  end

  # action = all
  # action = export
  # action = other

  # :global permission
  # :account permission
  #   allowed
  #   not allowed
  # :self
  #   allowed
  #   not allowed
  # other
  # check permission
  # check scope

  describe "bounce/1 with action = all" do
    test "with global permission (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      permission = %Permission{actor: actor, action: :all, type: :wallets, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{account_wallets: :global, end_user_wallets: :global}
    end

    test "with accounts permission (authorized)" do
      actor = insert(:admin, global_role: "admin")
      permission = %Permission{actor: actor, action: :all, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts, end_user_wallets: :accounts}
    end

    test "with self permission (authorized)" do
      actor = insert(:user, global_role: "end_user")
      permission = %Permission{actor: actor, action: :all, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "end_user"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :self}
    end

    test "with none role (unauthorized)" do
      actor = insert(:admin, global_role: "none")

      permission = %Permission{actor: actor, action: :all, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
    end

    test "with no permissions (unauthorized)" do
      actor = insert(:admin, global_role: nil)

      permission = %Permission{actor: actor, action: :all, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
    end
  end

  describe "bounce/1 with action = export" do
    test "with global permission (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      permission = %Permission{actor: actor, action: :export, type: :wallets, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{account_wallets: :global, end_user_wallets: :global}
    end

    test "with accounts permission (authorized)" do
      actor = insert(:admin, global_role: "admin")
      permission = %Permission{actor: actor, action: :export, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts, end_user_wallets: :accounts}
    end

    test "with self permission (authorized)" do
      actor = insert(:user, global_role: "end_user")
      permission = %Permission{actor: actor, action: :export, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "end_user"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :self}
    end

    test "with none role (unauthorized)" do
      actor = insert(:admin, global_role: "none")

      permission = %Permission{actor: actor, action: :export, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
    end

    test "with no permissions (unauthorized)" do
      actor = insert(:admin, global_role: nil)

      permission = %Permission{actor: actor, action: :export, type: :wallet, schema: Wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none, end_user_wallets: :none}
    end
  end

  describe "bounce/1 with action = get" do
    test "with global permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{end_user_wallets: :global}
    end

    test "with global permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{account_wallets: :global}
    end

    test "with accounts permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and end user wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with accounts permission and account wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with self permission and end user wallet (authorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      wallet = User.get_primary_wallet(actor)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "end_user"
      assert res.global_abilities == %{end_user_wallets: :self}
    end

    test "with self permission and account wallet (unauthorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "end_user"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with none global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with none global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with nil global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with nil global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end
  end

  describe "bounce/1 with action = create" do
    test "with global permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{end_user_wallets: :global}
    end

    test "with global permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{account_wallets: :global}
    end

    test "with accounts permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and end user wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with accounts permission and account wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with self permission and end user wallet (authorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      wallet = User.get_primary_wallet(actor)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "end_user"
      assert res.global_abilities == %{end_user_wallets: :self}
    end

    test "with self permission and account wallet (unauthorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "end_user"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with none global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with none global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with nil global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with nil global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :create, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end
  end

  describe "bounce/1 with action = update" do
    test "with global permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{end_user_wallets: :global}
    end

    test "with global permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "super_admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{account_wallets: :global}
    end

    test "with accounts permission and end user wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :get, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and end user wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{end_user_wallets: :accounts}
    end

    test "with accounts permission and account wallet (authorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {:ok, _} = Membership.assign(actor, account, "viewer", %System{})

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with accounts permission and account wallet (unauthorized)" do
      actor = insert(:admin, global_role: "admin")
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "admin"
      assert res.global_abilities == %{account_wallets: :accounts}
    end

    test "with self permission and end user wallet (authorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      wallet = User.get_primary_wallet(actor)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == true
      assert res.global_role == "end_user"
      assert res.global_abilities == %{end_user_wallets: :self}
    end

    test "with self permission and account wallet (unauthorized)" do
      {:ok, actor} = :user |> params_for(global_role: "end_user") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "end_user"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with none global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with none global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: "none") |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end

    test "with nil global role and end user wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{end_user_wallets: :none}
    end

    test "with nil global role and account wallet (unauthorized)" do
      {:ok, actor} = :admin |> params_for(global_role: nil) |> User.insert()
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      permission = %Permission{actor: actor, action: :update, target: wallet}

      res =
        GlobalBouncer.bounce(permission, %{
          dispatch_config: DispatchConfig,
          global_permissions: permissions()
        })

      assert res.global_authorized == false
      assert res.global_role == "none"
      assert res.global_abilities == %{account_wallets: :none}
    end
  end
end
