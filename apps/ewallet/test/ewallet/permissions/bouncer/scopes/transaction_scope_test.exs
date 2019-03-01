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

defmodule EWallet.Bouncer.TransactionScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, TransactionScope}
  alias EWalletDB.{AccountUser, Membership, Repo}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities (account: global / end_user:*)" do
    test "returns Transaction as queryable when 'global / global' ability" do
      actor = insert(:admin)
      transaction_1 = insert(:transaction)
      transaction_2 = insert(:transaction)
      transaction_3 = insert(:transaction)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :global,
          end_user_transactions: :global
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
    end

    test "returns Transaction as queryable when 'global / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :global,
          end_user_transactions: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      assert Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      assert Enum.member?(transaction_uuids, transaction_8.uuid)
      refute Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 8
    end

    test "returns Transaction as queryable when 'global / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :global,
          end_user_transactions: :self
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      assert Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      refute Enum.member?(transaction_uuids, transaction_7.uuid)
      refute Enum.member?(transaction_uuids, transaction_8.uuid)
      assert Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 7
    end

    test "returns Transaction as queryable when 'global / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :global,
          end_user_transactions: :self
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      assert Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      refute Enum.member?(transaction_uuids, transaction_7.uuid)
      refute Enum.member?(transaction_uuids, transaction_8.uuid)
      refute Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 6
    end
  end

  describe "scope_query/1 with global abilities (account: accounts / end_user:*)" do
    test "returns Transaction as queryable when 'accounts / global' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :accounts,
          end_user_transactions: :global
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      refute Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      assert Enum.member?(transaction_uuids, transaction_8.uuid)
      assert Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 8
    end

    test "returns Transaction as queryable when 'accounts / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :accounts,
          end_user_transactions: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      refute Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      assert Enum.member?(transaction_uuids, transaction_8.uuid)
      refute Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 7
    end

    test "returns Transaction as queryable when 'accounts / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :accounts,
          end_user_transactions: :self
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      refute Enum.member?(transaction_uuids, transaction_3.uuid)
      assert Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      refute Enum.member?(transaction_uuids, transaction_8.uuid)
      assert Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 7
    end

    test "returns Transaction as queryable when 'accounts / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :accounts,
          end_user_transactions: :none
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      assert Enum.member?(transaction_uuids, transaction_2.uuid)
      refute Enum.member?(transaction_uuids, transaction_3.uuid)
      assert Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      refute Enum.member?(transaction_uuids, transaction_7.uuid)
      refute Enum.member?(transaction_uuids, transaction_8.uuid)
      refute Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 5
    end
  end

  describe "scope_query/1 with global abilities (account: none / end_user:*)" do
    test "returns Transaction as queryable when 'none / global' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :none,
          end_user_transactions: :global
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      refute Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      refute Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      assert Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      assert Enum.member?(transaction_uuids, transaction_8.uuid)
      assert Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 7
    end

    test "returns Transaction as queryable when 'none / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: end_user_1.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_3.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_4.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :none,
          end_user_transactions: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(transaction_uuids, transaction_1.uuid)
      refute Enum.member?(transaction_uuids, transaction_2.uuid)
      assert Enum.member?(transaction_uuids, transaction_3.uuid)
      refute Enum.member?(transaction_uuids, transaction_4.uuid)
      assert Enum.member?(transaction_uuids, transaction_5.uuid)
      refute Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      assert Enum.member?(transaction_uuids, transaction_8.uuid)
      refute Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 5
    end

    test "returns Transaction as queryable when 'none / self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)
      end_user_4 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      transaction_1 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_2 =
        insert(:transaction,
          from_account_uuid: account_2.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_3 =
        insert(:transaction,
          from_account_uuid: account_3.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_1.uuid,
          to_account_uuid: nil
        )

      transaction_4 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: nil,
          to_account_uuid: account_4.uuid
        )

      transaction_5 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_6 =
        insert(:transaction,
          from_account_uuid: account_1.uuid,
          from_user_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_7 =
        insert(:transaction,
          from_user_uuid: actor.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_2.uuid,
          to_account_uuid: nil
        )

      transaction_8 =
        insert(:transaction,
          from_user_uuid: end_user_2.uuid,
          from_account_uuid: nil,
          to_user_uuid: end_user_3.uuid,
          to_account_uuid: nil
        )

      transaction_9 =
        insert(:transaction,
          from_user_uuid: end_user_4.uuid,
          from_account_uuid: nil,
          to_user_uuid: actor.uuid,
          to_account_uuid: nil
        )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :none,
          end_user_transactions: :self
        },
        account_abilities: %{}
      }

      query = TransactionScope.scoped_query(permission)
      transaction_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(transaction_uuids, transaction_1.uuid)
      refute Enum.member?(transaction_uuids, transaction_2.uuid)
      refute Enum.member?(transaction_uuids, transaction_3.uuid)
      refute Enum.member?(transaction_uuids, transaction_4.uuid)
      refute Enum.member?(transaction_uuids, transaction_5.uuid)
      refute Enum.member?(transaction_uuids, transaction_6.uuid)
      assert Enum.member?(transaction_uuids, transaction_7.uuid)
      refute Enum.member?(transaction_uuids, transaction_8.uuid)
      assert Enum.member?(transaction_uuids, transaction_9.uuid)
      assert length(transaction_uuids) == 2
    end

    test "returns Transaction as queryable when 'none / none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      insert(:transaction,
        from_account_uuid: account_1.uuid,
        from_user_uuid: nil,
        to_user_uuid: end_user_1.uuid,
        to_account_uuid: nil
      )

      insert(:transaction,
        from_account_uuid: account_2.uuid,
        from_user_uuid: nil,
        to_user_uuid: end_user_1.uuid,
        to_account_uuid: nil
      )

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transactions: :none,
          end_user_transactions: :none
        },
        account_abilities: %{}
      }

      assert TransactionScope.scoped_query(permission) == nil
    end
  end
end
