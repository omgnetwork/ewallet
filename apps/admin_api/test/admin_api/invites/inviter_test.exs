defmodule AdminAPI.InviterTest do
  use AdminAPI.ConnCase
  use Bamboo.Test
  alias AdminAPI.Inviter
  alias EWalletDB.Invite

  describe "Inviter.invite/3" do
    test "sends email and returns the invite if successful" do
      account = insert(:account)
      role    = insert(:role)

      {res, invite} = Inviter.invite("test@example.com", account, role)

      assert res       == :ok
      assert %Invite{}  = invite
      assert_delivered_email AdminAPI.InviteEmail.create(invite)
    end

    test "sends a new invite if this email has been invited before" do
      account = insert(:account)
      role    = insert(:role)

      {:ok, invite1} = Inviter.invite("test@example.com", account, role)
      {:ok, invite2} = Inviter.invite("test@example.com", account, role)

      assert_delivered_email AdminAPI.InviteEmail.create(invite1)
      assert_delivered_email AdminAPI.InviteEmail.create(invite2)
    end

    test "returns :invalid_email error if email is invalid" do
      email   = "not-an-email"
      account = insert(:account)
      role    = insert(:role)

      {res, error} = Inviter.invite(email, account, role)

      assert res   == :error
      assert error == :invalid_email
    end

    test "returns :user_already_active error if user is already active" do
      _user   = insert(:admin, %{email: "activeuser@example.com"}) # This should already be an active user
      account = insert(:account)
      role    = insert(:role)

      {res, error} = Inviter.invite("activeuser@example.com", account, role)

      assert res   == :error
      assert error == :user_already_active
    end
  end
end
