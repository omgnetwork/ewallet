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

defmodule EWallet.Bouncer.WalletScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, WalletScope}
  alias EWalletDB.{AccountUser, Membership, Wallet, Repo}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  setup do
    {2, _} = Repo.delete_all(Wallet)

    :ok
  end

  describe "scope_query/1 with global abilities (account: global / end_user:*)" do
    test "returns Wallet as queryable when 'global / global' ability" do
      actor = insert(:admin)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)
      wallet_3 = insert(:wallet)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :global
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)

      assert length(wallet_uuids) == 3
    end

    test "returns all wallets the actor (user) has access to when 'global / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_7 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :accounts
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      assert Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)

      assert length(wallet_uuids) == 7
    end

    test "returns all wallets the actor (key) has access to when 'global / accounts' ability" do
      actor = insert(:key)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_7 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :accounts
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      assert Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 7
    end

    test "returns all wallets the actor (user) has access to when 'global / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())
      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :self
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      assert Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 6
    end

    test "returns all wallets the actor (key) has access to when 'global / self' ability" do
      actor = insert(:key)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_7 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :self
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      assert Enum.member?(wallet_uuids, wallet_5.uuid)
      refute Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 5
    end

    test "returns all wallets the actor (user) has access to when 'global / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())
      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :global,
          end_user_wallets: :none
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      assert Enum.member?(wallet_uuids, wallet_5.uuid)
      refute Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 5
    end
  end

  describe "scope_query/1 with global abilities (account: accounts / end_user:*)" do
    test "returns all wallets the actor (user) has access to when 'accounts / global' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_7 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :accounts,
          end_user_wallets: :global
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      refute Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      assert Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 6
    end

    test "returns all wallets the actor (user) has access to when 'accounts / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :accounts,
          end_user_wallets: :accounts
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      refute Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      assert Enum.member?(wallet_uuids, wallet_8.uuid)
      assert Enum.member?(wallet_uuids, wallet_9.uuid)
      refute Enum.member?(wallet_uuids, wallet_10.uuid)
      assert length(wallet_uuids) == 7
    end

    test "returns all wallets the actor (user) has access to when 'accounts / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :accounts,
          end_user_wallets: :self
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      refute Enum.member?(wallet_uuids, wallet_9.uuid)
      refute Enum.member?(wallet_uuids, wallet_10.uuid)
      assert length(wallet_uuids) == 5
    end

    test "returns all wallets the actor (user) has access to when 'accounts / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :accounts,
          end_user_wallets: :self
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(wallet_uuids, wallet_1.uuid)
      assert Enum.member?(wallet_uuids, wallet_2.uuid)
      assert Enum.member?(wallet_uuids, wallet_3.uuid)
      assert Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      refute Enum.member?(wallet_uuids, wallet_9.uuid)
      refute Enum.member?(wallet_uuids, wallet_10.uuid)
      assert length(wallet_uuids) == 5
    end
  end

  describe "scope_query/1 with global abilities (account: none / end_user:*)" do
    test "returns all wallets the actor (user) has access to when 'none / global' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      wallet_6 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_7 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_8 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :none,
          end_user_wallets: :global
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      refute Enum.member?(wallet_uuids, wallet_1.uuid)
      refute Enum.member?(wallet_uuids, wallet_2.uuid)
      refute Enum.member?(wallet_uuids, wallet_3.uuid)
      refute Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      assert Enum.member?(wallet_uuids, wallet_8.uuid)
      assert length(wallet_uuids) == 3
    end

    test "returns all wallets the actor (user) has access to when 'none / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :none,
          end_user_wallets: :accounts
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      refute Enum.member?(wallet_uuids, wallet_1.uuid)
      refute Enum.member?(wallet_uuids, wallet_2.uuid)
      refute Enum.member?(wallet_uuids, wallet_3.uuid)
      refute Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      refute Enum.member?(wallet_uuids, wallet_6.uuid)
      assert Enum.member?(wallet_uuids, wallet_7.uuid)
      assert Enum.member?(wallet_uuids, wallet_8.uuid)
      assert Enum.member?(wallet_uuids, wallet_9.uuid)
      refute Enum.member?(wallet_uuids, wallet_10.uuid)
      assert length(wallet_uuids) == 3
    end

    test "returns all wallets the actor (user) has access to when 'none / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())
      wallet_2 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))
      wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :none,
          end_user_wallets: :self
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      refute Enum.member?(wallet_uuids, wallet_1.uuid)
      refute Enum.member?(wallet_uuids, wallet_2.uuid)
      refute Enum.member?(wallet_uuids, wallet_3.uuid)
      refute Enum.member?(wallet_uuids, wallet_4.uuid)
      refute Enum.member?(wallet_uuids, wallet_5.uuid)
      assert Enum.member?(wallet_uuids, wallet_6.uuid)
      refute Enum.member?(wallet_uuids, wallet_7.uuid)
      refute Enum.member?(wallet_uuids, wallet_8.uuid)
      refute Enum.member?(wallet_uuids, wallet_9.uuid)
      refute Enum.member?(wallet_uuids, wallet_10.uuid)
      assert length(wallet_uuids) == 1
    end

    test "returns all wallets the actor (user) has access to when 'none / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # wallets for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      _wallet_1 = insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary())

      _wallet_2 =
        insert(:wallet, user: nil, account: account_1, identifier: Wallet.secondary("1"))

      _wallet_3 = insert(:wallet, user: nil, account: account_2, identifier: Wallet.secondary())
      _wallet_4 = insert(:wallet, user: nil, account: account_3, identifier: Wallet.secondary())
      _wallet_5 = insert(:wallet, user: nil, account: account_4, identifier: Wallet.secondary())

      # wallets for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      _wallet_6 = insert(:wallet, user: actor, account: nil, identifier: Wallet.secondary())
      _wallet_7 = insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary())

      _wallet_8 =
        insert(:wallet, user: end_user_1, account: nil, identifier: Wallet.secondary("1"))

      _wallet_9 = insert(:wallet, user: end_user_2, account: nil, identifier: Wallet.secondary())
      _wallet_10 = insert(:wallet, user: end_user_3, account: nil, identifier: Wallet.secondary())

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_wallets: :none,
          end_user_wallets: :none
        },
        account_abilities: %{}
      }

      query = WalletScope.scoped_query(permission)
      assert query == nil
    end
  end
end
