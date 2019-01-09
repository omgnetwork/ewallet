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

defmodule EWallet.Web.InviterTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  use Bamboo.Test
  alias ActivityLogger.System
  alias EWallet.Web.{Inviter, MockInviteEmail, Preloader}
  alias EWalletDB.{Account, Invite, Membership, User}

  @user_redirect_url "http://localhost:4000/some_redirect_url?email={email}&token={token}"
  @user_success_url "http://localhost:4000/some_success_url"
  @admin_redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "invite_user/5" do
    test "sends email and returns the invite if successful" do
      {res, invite} =
        Inviter.invite_user(
          "test@example.com",
          "password",
          @user_redirect_url,
          @user_success_url,
          &MockInviteEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
    end

    test "links the user with master account" do
      {:ok, invite} =
        Inviter.invite_user(
          "test@example.com",
          "password",
          @user_redirect_url,
          @user_success_url,
          &MockInviteEmail.create/2
        )

      {:ok, invite} = Preloader.preload_one(invite, :user)
      accounts = User.get_all_linked_accounts(invite.user.uuid)
      assert Enum.any?(accounts, fn account -> Account.master?(account) end)
    end

    test "resends the verification email if the user has not verified their email" do
      invite = insert(:invite)
      {:ok, user} = :standalone_user |> params_for(invite: invite) |> User.insert()

      {res, invite} =
        Inviter.invite_user(
          user.email,
          "password",
          @user_redirect_url,
          @user_success_url,
          &MockInviteEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(MockInviteEmail.create(invite, @user_redirect_url))

      {:ok, invite} = Preloader.preload_one(invite, :user)
      assert invite.user.uuid == user.uuid
    end

    test "returns :user_already_active error if user is already active" do
      _user = insert(:user, %{email: "activeuser@example.com"})

      {res, error} =
        Inviter.invite_user(
          "activeuser@example.com",
          "password",
          @user_redirect_url,
          @user_success_url,
          &MockInviteEmail.create/2
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "invite_admin/5" do
    test "sends email and returns the invite if successful" do
      user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {res, invite} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          user,
          &MockInviteEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(MockInviteEmail.create(invite, @admin_redirect_url))
    end

    test "sends a new invite if this email has been invited before" do
      user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {:ok, invite1} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          user,
          &MockInviteEmail.create/2
        )

      {:ok, invite2} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          user,
          &MockInviteEmail.create/2
        )

      assert_delivered_email(MockInviteEmail.create(invite1, @admin_redirect_url))
      assert_delivered_email(MockInviteEmail.create(invite2, @admin_redirect_url))
    end

    test "assigns the user to account and role" do
      user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {:ok, invite} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          user,
          &MockInviteEmail.create/2
        )

      memberships = Membership.all_by_user(invite.user)

      assert Enum.any?(memberships, fn m ->
               m.account_uuid == account.uuid && m.role_uuid == role.uuid
             end)
    end

    test "returns :user_already_active error if user is already active" do
      # This should already be an active user
      user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {res, error} =
        Inviter.invite_admin(
          "activeuser@example.com",
          account,
          role,
          @admin_redirect_url,
          user,
          &MockInviteEmail.create/2
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "send_email/3" do
    test "creates and sends the invite email" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      {res, _} = Inviter.send_email(invite, @admin_redirect_url, &MockInviteEmail.create/2)

      assert res == :ok
      assert_delivered_email(MockInviteEmail.create(invite, @admin_redirect_url))
    end
  end
end
