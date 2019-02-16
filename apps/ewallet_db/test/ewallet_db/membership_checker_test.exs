# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.MembershipCheckerTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.MembershipChecker
  alias EWalletDB.{Membership, Repo}

  setup do
    user = insert(:user)

    account_1 = insert(:account)
    account_2 = insert(:account, parent: account_1)
    account_3 = insert(:account, parent: account_2)

    # Lower number = higher priority
    # Starts with a really high number to avoid conflict with other role inserts
    role_high = insert(:role, priority: 111_111_111)
    role_low = insert(:role, priority: 999_999_999)

    %{
      user: user,
      account_1: account_1,
      account_2: account_2,
      account_3: account_3,
      role_high: role_high,
      role_low: role_low,
      originator: user
    }
  end

  describe "allowed?/4" do
    # Test for existing memberships with the direct account

    test "returns true when the user is not a member of the given account", ctx do
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
    end

    test "returns true when the user has a lower role in the given account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_low)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
    end

    test "returns false when the user has a higher role in the given account", ctx do
      _ = insert(:membership, user: ctx.user, account: ctx.account_1, role: ctx.role_high)
      refute MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_low, ctx.originator)
    end

    test "returns true when the user has the same role in the given account", ctx do
      _ = insert(:membership, user: ctx.user, account: ctx.account_1, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
    end

    # Test for existing memberships with a parent account

    test "returns true when the user has a lower role in a direct parent account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_low)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
    end

    test "returns false when the user has a higher role in a direct parent account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_high)
      refute MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_low, ctx.originator)
    end

    test "returns true when the user has the same role in a direct parent account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
    end

    # Test for existing memberships with an ancestor account

    test "returns true when the user has a lower role in an ancestor account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_low)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_3, ctx.role_high, ctx.originator)
    end

    test "returns false when the user has a higher role in an ancestor account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_high)
      refute MembershipChecker.allowed?(ctx.user, ctx.account_3, ctx.role_low, ctx.originator)
    end

    test "returns true when the user has the same role in an ancestor account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_1, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_3, ctx.role_high, ctx.originator)
    end

    # Test for existing memberships with a child account

    test "returns true when the user has a lower role in a child account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_low)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
    end

    test "returns true when the user has a higher role in a child account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_low, ctx.originator)
    end

    test "returns true when the user has the same role in a child account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
    end

    # Test for redundant membership pruning on a child account

    test "deletes a lower priority membership in a child account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_low)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
      refute Repo.get(Membership, membership.uuid)
    end

    test "keeps the higher priority membership in a child account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_low, ctx.originator)
      assert Repo.get(Membership, membership.uuid)
    end

    test "deletes the same priority membership in a child account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_2, ctx.role_high, ctx.originator)
      refute Repo.get(Membership, membership.uuid)
    end

    # Test for existing memberships with a descendant account

    test "returns true when the user has a lower role in a descendant account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_low)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
    end

    test "returns true when the user has a higher role in a descendant account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_low, ctx.originator)
    end

    test "returns true when the user has the same role in a descendant account", ctx do
      _ = insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
    end

    # Test for redundant membership pruning on a descendant account

    test "deletes a lower priority membership in a descendant account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_low)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
      refute Repo.get(Membership, membership.uuid)
    end

    test "keeps the higher priority membership in a descendant account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_low, ctx.originator)
      assert Repo.get(Membership, membership.uuid)
    end

    test "deletes the same priority membership in a descendant account", ctx do
      membership =
        insert(:membership, user: ctx.originator, account: ctx.account_3, role: ctx.role_high)

      assert Repo.get(Membership, membership.uuid)
      assert MembershipChecker.allowed?(ctx.user, ctx.account_1, ctx.role_high, ctx.originator)
      refute Repo.get(Membership, membership.uuid)
    end
  end
end
