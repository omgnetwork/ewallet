defmodule EWallet.Web.InviterTest do
  use AdminAPI.ConnCase
  use Bamboo.Test
  alias AdminAPI.InviteEmail
  alias EWallet.Web.Inviter
  alias EWalletDB.{Invite, Membership, Repo}

  @redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "invite/3" do
    test "sends email and returns the invite if successful" do
      account = insert(:account)
      role = insert(:role)

      {res, invite} =
        Inviter.invite("test@example.com", account, role, @redirect_url, InviteEmail)

      assert res == :ok
      assert %Invite{} = invite
      assert_delivered_email(InviteEmail.create(invite, @redirect_url))
    end

    test "sends a new invite if this email has been invited before" do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite1} =
        Inviter.invite("test@example.com", account, role, @redirect_url, InviteEmail)

      {:ok, invite2} =
        Inviter.invite("test@example.com", account, role, @redirect_url, InviteEmail)

      assert_delivered_email(InviteEmail.create(invite1, @redirect_url))
      assert_delivered_email(InviteEmail.create(invite2, @redirect_url))
    end

    test "assigns the user to account and role" do
      account = insert(:account)
      role = insert(:role)

      {:ok, invite} =
        Inviter.invite("test@example.com", account, role, @redirect_url, InviteEmail)

      memberships = Membership.all_by_user(invite.user)

      assert Enum.any?(memberships, fn m ->
               m.account_uuid == account.uuid && m.role_uuid == role.uuid
             end)
    end

    test "returns :invalid_email error if email is invalid" do
      email = "not-an-email"
      account = insert(:account)
      role = insert(:role)

      {res, error} = Inviter.invite(email, account, role, @redirect_url, InviteEmail)

      assert res == :error
      assert error == :invalid_email
    end

    test "returns :user_already_active error if user is already active" do
      # This should already be an active user
      _user = insert(:admin, %{email: "activeuser@example.com"})
      account = insert(:account)
      role = insert(:role)

      {res, error} =
        Inviter.invite("activeuser@example.com", account, role, @redirect_url, InviteEmail)

      assert res == :error
      assert error == :user_already_active
    end
  end

  describe "send_email/3" do
    test "creates and sends the invite email" do
      invite = insert(:invite)
      _user = insert(:admin, %{invite: invite})
      invite = invite |> Repo.preload(:user)
      {res, _} = Inviter.send_email(invite, @redirect_url, InviteEmail)

      assert res == :ok
      assert_delivered_email(InviteEmail.create(invite, @redirect_url))
    end

    test "returns :invalid_parameter error if the redirect_url value is not allowed" do
      invite = insert(:invite)
      redirect_url = "http://unknown.com/invite?email={email}&token={token}"
      {res, code, description} = Inviter.send_email(invite, redirect_url, InviteEmail)

      assert res == :error
      assert code == :invalid_parameter
      assert description == "The `redirect_url` is not allowed to be used. Got: #{redirect_url}"
    end
  end
end
