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

defmodule EWallet.Bouncer.UserScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, UserScope}
  alias EWalletDB.{AccountUser, Membership, Repo}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities (account: global / end_user:*)" do
    test "returns the appropriate query when 'global / global' ability" do
      actor = insert(:admin)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :global
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)
      assert Enum.member?(user_uuids, user_1.uuid)
      assert Enum.member?(user_uuids, user_2.uuid)
      assert Enum.member?(user_uuids, user_3.uuid)
    end

    test "returns all users the actor (user) has access to when 'global / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :accounts
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, end_user_1.uuid)
      assert Enum.member?(user_uuids, end_user_2.uuid)
      assert Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 7
    end

    test "returns all users the actor (user) has access to when 'global / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :self
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 4
    end

    test "returns all users the actor (end_user) has access to when 'global / self' ability" do
      actor = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :self
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, actor.uuid)
      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 4
    end

    test "returns all users the actor (admin) has access to when 'global / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :none
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 4
    end

    test "returns all users the actor (end_user) has access to when 'global / none' ability" do
      actor = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :none
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, actor.uuid)
      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 3
    end
  end

  describe "scope_query/1 with global abilities (account: accounts / end_user:*)" do
    test "returns the appropriate query when 'accounts / global' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :accounts,
          end_users: :global
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, end_user_1.uuid)
      assert Enum.member?(user_uuids, end_user_2.uuid)
      assert Enum.member?(user_uuids, end_user_3.uuid)
      assert Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 7
    end

    test "returns the appropriate query when 'accounts / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :accounts,
          end_users: :accounts
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, end_user_1.uuid)
      assert Enum.member?(user_uuids, end_user_2.uuid)
      assert Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 6
    end

    test "returns the appropriate query when 'accounts / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :accounts,
          end_users: :self
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 3
    end

    test "returns the appropriate query when 'accounts / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :accounts,
          end_users: :none
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)
      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 3
    end
  end

  describe "scope_query/1 with global abilities (account: none / end_user:*)" do
    test "returns the appropriate query when 'none / global' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :none,
          end_users: :global
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(user_uuids, actor.uuid)
      refute Enum.member?(user_uuids, admin_1.uuid)
      refute Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, end_user_1.uuid)
      assert Enum.member?(user_uuids, end_user_2.uuid)
      assert Enum.member?(user_uuids, end_user_3.uuid)
      assert Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 4
    end

    test "returns the appropriate query when 'none / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :none,
          end_users: :accounts
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(user_uuids, actor.uuid)
      refute Enum.member?(user_uuids, admin_1.uuid)
      refute Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      assert Enum.member?(user_uuids, end_user_1.uuid)
      assert Enum.member?(user_uuids, end_user_2.uuid)
      assert Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 3
    end

    test "returns the appropriate query (admin) when 'none / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :none,
          end_users: :self
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)

      refute Enum.member?(user_uuids, admin_1.uuid)
      refute Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 1
    end

    test "returns the appropriate query (end user) when 'none / self' ability" do
      actor = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :none,
          end_users: :self
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, actor.uuid)

      refute Enum.member?(user_uuids, admin_1.uuid)
      refute Enum.member?(user_uuids, admin_2.uuid)
      refute Enum.member?(user_uuids, admin_3.uuid)

      refute Enum.member?(user_uuids, end_user_1.uuid)
      refute Enum.member?(user_uuids, end_user_2.uuid)
      refute Enum.member?(user_uuids, end_user_3.uuid)
      refute Enum.member?(user_uuids, end_user_4.uuid)

      assert length(user_uuids) == 1
    end

    test "returns the appropriate query when 'none / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(admin_1, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(admin_3, account_3, "viewer", %System{})

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, end_user_3.uuid, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :none,
          end_users: :none
        },
        account_abilities: %{}
      }

      assert UserScope.scoped_query(permission) == nil
    end
  end
end
