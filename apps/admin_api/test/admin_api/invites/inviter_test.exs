defmodule AdminAPI.InviterTest do
  use AdminAPI.ConnCase
  use Bamboo.Test
  alias AdminAPI.{Inviter, InviteEmail}
  alias EWalletDB.{Invite, Membership}

  @redirect_url "https://invite_url/?email={email}&token={token}"

  describe "Inviter.invite/3" do
    test "sends email and returns the invite if successful" do
      account = insert(:account)
      role    = insert(:role)

      {res, invite} = Inviter.invite("test@example.com", account, role, @redirect_url)

      assert res       == :ok
      assert %Invite{} =  invite
      assert_delivered_email InviteEmail.create(invite, @redirect_url)
    end

    test "sends a new invite if this email has been invited before" do
      account = insert(:account)
      role    = insert(:role)

      {:ok, invite1} = Inviter.invite("test@example.com", account, role, @redirect_url)
      {:ok, invite2} = Inviter.invite("test@example.com", account, role, @redirect_url)

      assert_delivered_email InviteEmail.create(invite1, @redirect_url)
      assert_delivered_email InviteEmail.create(invite2, @redirect_url)
    end

    test "assigns the user to account and role" do
      account = insert(:account)
      role    = insert(:role)

      {:ok, invite} = Inviter.invite("test@example.com", account, role, @redirect_url)
      memberships   = Membership.all_by_user(invite.user)

      assert Enum.any?(memberships, fn(m) ->
        m.account_id == account.id && m.role_id == role.id
      end)
    end

    test "returns :invalid_email error if email is invalid" do
      email   = "not-an-email"
      account = insert(:account)
      role    = insert(:role)

      {res, error} = Inviter.invite(email, account, role, @redirect_url)

      assert res   == :error
      assert error == :invalid_email
    end

    test "returns :user_already_active error if user is already active" do
      _user   = insert(:admin, %{email: "activeuser@example.com"}) # This should already be an active user
      account = insert(:account)
      role    = insert(:role)

      {res, error} = Inviter.invite("activeuser@example.com", account, role, @redirect_url)

      assert res   == :error
      assert error == :user_already_active
    end
  end
end
