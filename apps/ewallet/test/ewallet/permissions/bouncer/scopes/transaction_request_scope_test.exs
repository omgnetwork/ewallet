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

defmodule EWallet.Bouncer.TransactionRequestScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, TransactionRequestScope}
  alias EWalletDB.{AccountUser, Membership, Repo}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities (account: global / end_user:*)" do
    test "returns TransactionRequest as queryable when 'global / global' ability" do
      actor = insert(:admin)
      request_1 = insert(:transaction_request)
      request_2 = insert(:transaction_request)
      request_3 = insert(:transaction_request)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :global
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
    end

    test "returns all transaction requests the actor (user) has access to when 'global / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      assert Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 7
    end

    test "returns all transaction requests the actor (key) has access to when 'global / accounts' ability" do
      actor = insert(:key)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      assert Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 7
    end

    test "returns all transaction requests the actor (user) has access to when 'global / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :self
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      assert Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 6
    end

    test "returns all transaction requests the actor (key) has access to when 'global / self' ability" do
      actor = insert(:key)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :self
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      assert Enum.member?(request_uuids, request_5.uuid)
      refute Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 5
    end

    test "returns all transaction requests the actor (user) has access to when 'global / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :global,
          end_user_transaction_requests: :none
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      assert Enum.member?(request_uuids, request_5.uuid)
      refute Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 5
    end
  end

  describe "scope_query/1 with global abilities (account: accounts / end_user:*)" do
    test "returns all transaction requests the actor (user) has access to when 'accounts / global' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :accounts,
          end_user_transaction_requests: :global
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      refute Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      assert Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 6
    end

    test "returns all transaction requests the actor (user) has access to when 'accounts / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_9 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      request_10 = insert(:transaction_request, user_uuid: end_user_3.uuid, account_uuid: nil)

      request_11 =
        insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: account_1.uuid)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :accounts,
          end_user_transaction_requests: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      refute Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      assert Enum.member?(request_uuids, request_8.uuid)
      assert Enum.member?(request_uuids, request_9.uuid)
      refute Enum.member?(request_uuids, request_10.uuid)
      assert Enum.member?(request_uuids, request_11.uuid)
      assert length(request_uuids) == 8
    end

    test "returns all transaction requests the actor (user) has access to when 'accounts / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_9 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      request_10 = insert(:transaction_request, user_uuid: end_user_3.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :accounts,
          end_user_transaction_requests: :self
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      refute Enum.member?(request_uuids, request_9.uuid)
      refute Enum.member?(request_uuids, request_10.uuid)
      assert length(request_uuids) == 5
    end

    test "returns all transaction requests the actor (user) has access to when 'accounts / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_9 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      request_10 = insert(:transaction_request, user_uuid: end_user_3.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :accounts,
          end_user_transaction_requests: :self
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(request_uuids, request_1.uuid)
      assert Enum.member?(request_uuids, request_2.uuid)
      assert Enum.member?(request_uuids, request_3.uuid)
      assert Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      refute Enum.member?(request_uuids, request_9.uuid)
      refute Enum.member?(request_uuids, request_10.uuid)
      assert length(request_uuids) == 5
    end
  end

  describe "scope_query/1 with global abilities (account: none / end_user:*)" do
    test "returns all transaction requests the actor (user) has access to when 'none / global' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :none,
          end_user_transaction_requests: :global
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(request_uuids, request_1.uuid)
      refute Enum.member?(request_uuids, request_2.uuid)
      refute Enum.member?(request_uuids, request_3.uuid)
      refute Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      assert Enum.member?(request_uuids, request_8.uuid)
      assert length(request_uuids) == 3
    end

    test "returns all transaction requests the actor (user) has access to when 'none / accounts' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_9 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      request_10 = insert(:transaction_request, user_uuid: end_user_3.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :none,
          end_user_transaction_requests: :accounts
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(request_uuids, request_1.uuid)
      refute Enum.member?(request_uuids, request_2.uuid)
      refute Enum.member?(request_uuids, request_3.uuid)
      refute Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      refute Enum.member?(request_uuids, request_6.uuid)
      assert Enum.member?(request_uuids, request_7.uuid)
      assert Enum.member?(request_uuids, request_8.uuid)
      assert Enum.member?(request_uuids, request_9.uuid)
      refute Enum.member?(request_uuids, request_10.uuid)
      assert length(request_uuids) == 3
    end

    test "returns all transaction requests the actor (user) has access to when 'none / self' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      end_user_1 = insert(:user)
      end_user_2 = insert(:user)
      end_user_3 = insert(:user)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      request_1 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_2 = insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)

      request_3 = insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      request_4 = insert(:transaction_request, user_uuid: nil, account_uuid: account_3.uuid)

      request_5 = insert(:transaction_request, user_uuid: nil, account_uuid: account_4.uuid)

      # requests for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_2.uuid, %System{})

      request_6 = insert(:transaction_request, user_uuid: actor.uuid, account_uuid: nil)

      request_7 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_8 = insert(:transaction_request, user_uuid: end_user_1.uuid, account_uuid: nil)

      request_9 = insert(:transaction_request, user_uuid: end_user_2.uuid, account_uuid: nil)

      request_10 = insert(:transaction_request, user_uuid: end_user_3.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :none,
          end_user_transaction_requests: :self
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      request_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      refute Enum.member?(request_uuids, request_1.uuid)
      refute Enum.member?(request_uuids, request_2.uuid)
      refute Enum.member?(request_uuids, request_3.uuid)
      refute Enum.member?(request_uuids, request_4.uuid)
      refute Enum.member?(request_uuids, request_5.uuid)
      assert Enum.member?(request_uuids, request_6.uuid)
      refute Enum.member?(request_uuids, request_7.uuid)
      refute Enum.member?(request_uuids, request_8.uuid)
      refute Enum.member?(request_uuids, request_9.uuid)
      refute Enum.member?(request_uuids, request_10.uuid)
      assert length(request_uuids) == 1
    end

    test "returns all transaction requests the actor (user) has access to when 'none / none' ability" do
      actor = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      # requests for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(actor, account_3, "viewer", %System{})

      insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)
      insert(:transaction_request, user_uuid: nil, account_uuid: account_1.uuid)
      insert(:transaction_request, user_uuid: nil, account_uuid: account_2.uuid)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          account_transaction_requests: :none,
          end_user_transaction_requests: :none
        },
        account_abilities: %{}
      }

      query = TransactionRequestScope.scoped_query(permission)
      assert query == nil
    end
  end
end
