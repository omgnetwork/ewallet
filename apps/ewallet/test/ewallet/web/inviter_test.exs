defmodule EWallet.Web.InviterTest do
  use AdminAPI.ConnCase
  use Bamboo.Test
  alias AdminAPI.InviteEmail
  alias EWallet.Web.Inviter
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.{Invite, Membership, Repo}

  describe "invite_user/5" do
    setup do
      %{
        redirect_url:
          "http://localhost:4000/pages/client/v1/verify_email?email={email}&token={token}",
        success_url: "http://localhost:4000/pages/client/v1/verify_email/success"
      }
    end

    test "sends email and returns the invite if successful", ctx do
      {res, invite} =
        Inviter.invite_user(
          "test@example.com",
          "password",
          ctx.redirect_url,
          ctx.success_url,
          VerificationEmail
        )

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(VerificationEmail.create(invite, ctx.redirect_url))
    end

    test "sends email with the default redirect_url if not given"

    test "sends email with the redirect_url in the email if given"

    test "sends a new invite if this email has been invited before but not verified"

    test "returns :invalid_email error if email is invalid", ctx do
      {res, error} =
        Inviter.invite_user(
          "not-an-email",
          "password",
          ctx.redirect_url,
          ctx.success_url,
          VerificationEmail
        )

      assert res == :error
      assert error == :invalid_email
    end

    test "returns :user_already_active error if user is already active", ctx do
      _user = insert(:user, %{email: "activeuser@example.com"})

      {res, error} =
        Inviter.invite_admin(
          "activeuser@example.com",
          "password",
          ctx.redirect_url,
          ctx.success_url,
          VerificationEmail
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "invite_admin/5" do
    setup do
      %{
        redirect_url: "http://localhost:4000/invite?email={email}&token={token}"
      }
    end

    test "sends email and returns the invite if successful", ctx do
      account = insert(:account)
      role = insert(:role)

      {res, invite} =
        Inviter.invite_admin("test@example.com", account, role, ctx.redirect_url, InviteEmail)

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(InviteEmail.create(invite, ctx.redirect_url))
    end

    test "sends a new invite if this email has been invited before", ctx do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite1} =
        Inviter.invite_admin("test@example.com", account, role, ctx.redirect_url, InviteEmail)

      {:ok, invite2} =
        Inviter.invite_admin("test@example.com", account, role, ctx.redirect_url, InviteEmail)

      assert_delivered_email(InviteEmail.create(invite1, ctx.redirect_url))
      assert_delivered_email(InviteEmail.create(invite2, ctx.redirect_url))
    end

    test "assigns the user to account and role", ctx do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite} =
        Inviter.invite_admin("test@example.com", account, role, ctx.redirect_url, InviteEmail)

      memberships = Membership.all_by_user(invite.user)

      assert Enum.any?(memberships, fn m ->
               m.account_uuid == account.uuid && m.role_uuid == role.uuid
             end)
    end

    test "returns :invalid_email error if email is invalid", ctx do
      email = "not-an-email"
      account = insert(:account)
      role = insert(:role)

      {res, error} = Inviter.invite_admin(email, account, role, ctx.redirect_url, InviteEmail)

      assert res == :error
      assert error == :invalid_email
    end

    test "returns :user_already_active error if user is already active", ctx do
      # This should already be an active user
      _user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {res, error} =
        Inviter.invite_admin(
          "activeuser@example.com",
          account,
          role,
          ctx.redirect_url,
          InviteEmail
        )

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "send_email/3" do
    setup do
      %{
        redirect_url: "http://localhost:4000/invite?email={email}&token={token}"
      }
    end

    test "creates and sends the invite email", ctx do
      invite = insert(:invite)
      _user = insert(:admin, %{invite: invite})
      invite = invite |> Repo.preload(:user)
      {res, _} = Inviter.send_email(invite, ctx.redirect_url, InviteEmail)

      assert res == :ok
      assert_delivered_email(InviteEmail.create(invite, ctx.redirect_url))
    end

    test "returns :invalid_parameter error if the redirect_url value is not allowed", _ctx do
      invite = insert(:invite)
      redirect_url = "http://unknown.com/invite?email={email}&token={token}"
      {res, code, description} = Inviter.send_email(invite, redirect_url, InviteEmail)

      assert res == :error
      assert code == :invalid_parameter

      assert description ==
               "The `redirect_url` is not allowed to be used. Got: '#{redirect_url}'."
    end
  end
end
