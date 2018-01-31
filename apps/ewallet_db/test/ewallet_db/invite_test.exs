defmodule EWalletDB.InviteTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Invite, User}
  alias EWalletDB.Helpers.Crypto
  alias Ecto.UUID

  describe "Invite.get/1" do
    test "returns an Invite if the given id is found" do
      invite = insert(:invite)
      result = Invite.get(invite.id)

      assert result.token == invite.token
    end

    test "returns nil if the given id is not found" do
      id = UUID.generate()
      assert Invite.get(id) == nil
    end
  end

  describe "Invite.get/2" do
    test "returns an Invite if the given email and token combo is found" do
      invite = insert(:invite, %{token: "the_token"})
      _user  = insert(:admin, %{
        email: "testemail@omise.co",
        invite: invite
      })

      assert %Invite{} = Invite.get("testemail@omise.co", "the_token")
    end

    test "returns nil if the given email and token combo is not found" do
      insert(:admin, %{
        email: "testemail@omise.co",
        invite: insert(:invite)
      })

      assert Invite.get("testemail@omise.co", "wrong_token") == nil
    end
  end

  describe "Invite.get/3" do
    test "returns an Invite if provided an existing user email" do
      insert(:admin, %{
        email: "testemail@omise.co",
        invite: insert(:invite)
      })

      assert %Invite{} = Invite.get(:user, :email, "testemail@omise.co")
    end

    test "returns nil if an Invite for the given email does not exist" do
      insert(:admin, %{
        email: "testemail@omise.co",
        invite: insert(:invite)
      })

      assert Invite.get(:user, :email, "wrongemail@omise.co") == nil
    end
  end

  describe "Invite.generate/2" do
    test "returns {:ok, invite} for the given user" do
      user             = insert(:admin)
      {result, invite} = Invite.generate(user)

      assert result == :ok
      assert %Invite{} = invite
    end

    test "associates the invite_id to the user" do
      user          = insert(:admin)
      {:ok, invite} = Invite.generate(user)

      user = User.get(user.id)
      assert user.invite_id == invite.id
    end

    test "preloads the invite if the option is given" do
      user          = insert(:admin)
      {:ok, invite} = Invite.generate(user, preload: :user)

      assert invite.user.id == user.id
    end
  end

  describe "Invite.accept/2" do
    test "sets user to :active status" do
      invite = insert(:invite)
      user   = insert(:admin, %{invite: invite})

      :pending_confirmation = User.get_status(user)
      {:ok, _invite}        = Invite.accept(invite, "some_password")
      status                = user.id |> User.get() |> User.get_status()

      assert status  == :active
    end

    test "sets user with the given password" do
      invite         = insert(:invite)
      user           = insert(:admin, %{invite: invite})
      {res, _invite} = Invite.accept(invite, "some_password")
      user           = User.get(user.id)

      assert res == :ok
      assert Crypto.verify_password("some_password", user.password_hash)
    end

    test "deletes the invite" do
      invite = insert(:invite)
      _user  = insert(:admin, %{invite: invite})

      {res, _invite} = Invite.accept(invite, "some_password")

      assert res == :ok
      assert Invite.get(invite.id) == nil
    end
  end
end
