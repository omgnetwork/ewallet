defmodule EWallet.Web.InviterTest do
  use AdminAPI.ConnCase
  use Bamboo.Test
  alias AdminAPI.InviteEmail
  alias EWallet.Web.{Inviter, Preloader}
  alias EWalletAPI.VerificationEmail
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
          &VerificationEmail.create/2
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
          &VerificationEmail.create/2
        )

      {:ok, invite} = Preloader.preload_one(invite, :user)
      accounts = User.get_all_linked_accounts(invite.user.uuid)
      assert Enum.any?(accounts, fn account -> Account.master?(account) end)
    end

    test "resends the verification email if the user has not verified their email" do
      invite = insert(:invite)
      user = insert(:standalone_user, invite: invite)

      {res, invite} =
        Inviter.invite_user(
          user.email,
          "password",
          @user_redirect_url,
          @user_success_url,
          &VerificationEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(VerificationEmail.create(invite, @user_redirect_url))

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
          &VerificationEmail.create/2
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "invite_admin/5" do
    test "sends email and returns the invite if successful" do
      account = insert(:account)
      role = insert(:role)

      {res, invite} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          &InviteEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(InviteEmail.create(invite, @admin_redirect_url))
    end

    test "sends a new invite if this email has been invited before" do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite1} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          &InviteEmail.create/2
        )

      {:ok, invite2} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          &InviteEmail.create/2
        )

      assert_delivered_email(InviteEmail.create(invite1, @admin_redirect_url))
      assert_delivered_email(InviteEmail.create(invite2, @admin_redirect_url))
    end

    test "assigns the user to account and role" do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite} =
        Inviter.invite_admin(
          "test@example.com",
          account,
          role,
          @admin_redirect_url,
          &InviteEmail.create/2
        )

      memberships = Membership.all_by_user(invite.user)

      assert Enum.any?(memberships, fn m ->
               m.account_uuid == account.uuid && m.role_uuid == role.uuid
             end)
    end

    test "returns :user_already_active error if user is already active" do
      # This should already be an active user
      _user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {res, error} =
        Inviter.invite_admin(
          "activeuser@example.com",
          account,
          role,
          @admin_redirect_url,
          &InviteEmail.create/2
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "send_email/3" do
    test "creates and sends the invite email" do
      {:ok, invite} = Invite.generate(insert(:admin))

      {res, _} = Inviter.send_email(invite, @admin_redirect_url, &InviteEmail.create/2)

      assert res == :ok
      assert_delivered_email(InviteEmail.create(invite, @admin_redirect_url))
    end
  end
end
