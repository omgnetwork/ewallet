defmodule EWalletDB.InviteTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias Utils.Helpers.Crypto
  alias EWalletDB.{Invite, User}
  alias ActivityLogger.System

  describe "Invite.get/1" do
    test "returns an Invite if the given id is found" do
      invite = insert(:invite)
      result = Invite.get(invite.uuid)

      assert result.token == invite.token
    end

    test "returns nil if the given id is not found" do
      uuid = UUID.generate()
      assert Invite.get(uuid) == nil
    end
  end

  describe "Invite.get/2" do
    test "returns an Invite if the given email and token combo is found" do
      invite = insert(:invite, %{token: "the_token"})

      _user =
        insert(:admin, %{
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

  describe "Invite.fetch/2" do
    test "returns `{:ok, invite}` if the given email and token combo is found" do
      invite = insert(:invite, %{token: "the_token"})

      _user =
        insert(:admin, %{
          email: "testemail@omise.co",
          invite: invite
        })

      assert {:ok, %Invite{}} = Invite.fetch("testemail@omise.co", "the_token")
    end

    test "returns `{:error, :email_token_not_found}` if the given email and token combo is not found" do
      insert(:admin, %{
        email: "testemail@omise.co",
        invite: insert(:invite)
      })

      assert Invite.fetch("testemail@omise.co", "wrong_token") == {:error, :email_token_not_found}
    end
  end

  describe "Invite.generate/2" do
    test "returns {:ok, invite} for the given user" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {result, invite} = Invite.generate(admin, %System{})

      assert result == :ok
      assert %Invite{} = invite
      assert invite.user_uuid == admin.uuid
      assert invite.verified_at == nil
    end

    test "associates the invite_uuid to the user" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})

      user = User.get(admin.id)
      assert user.invite_uuid == invite.uuid
    end

    test "sets the success_url if the option is given" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{}, success_url: "http://some_url")

      assert invite.success_url == "http://some_url"
    end

    test "preloads the invite if the option is given" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{}, preload: :user)

      assert invite.user.uuid == admin.uuid
    end
  end

  describe "Invite.accept/2" do
    test "sets user to :active status" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})
      user = User.get_by(uuid: invite.user_uuid)

      assert User.get_status(user) == :pending_confirmation

      {:ok, _invite} = Invite.accept(invite, "some_password", "some_password")

      user = User.get(user.id)
      assert User.get_status(user) == :active
    end

    test "sets user with the given password" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})

      {res, _invite} = Invite.accept(invite, "some_password", "some_password")
      admin = User.get(admin.id)

      assert res == :ok
      assert Crypto.verify_password("some_password", admin.password_hash)
    end

    test "disassociates the invite_uuid from the user" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})

      {res, _invite} = Invite.accept(invite, "some_password", "some_password")

      assert res == :ok
      assert User.get(admin.id).invite_uuid == nil
    end

    test "sets verified_at date time" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})

      {res, invite} = Invite.accept(invite, "some_password", "some_password")

      assert res == :ok
      assert invite.verified_at != nil
    end

    test "returns an {:error, changeset} tuple if passwords do not match" do
      {:ok, admin} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(admin, %System{})

      {res, changeset} = Invite.accept(invite, "some_password", "a_different_password")

      assert res == :error
      refute changeset.valid?

      assert Enum.member?(
               changeset.errors,
               {:password_confirmation, {"does not match password", [validation: :confirmation]}}
             )
    end
  end
end
