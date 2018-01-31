defmodule AdminAPI.InviteEmailTest do
  use AdminAPI.ConnCase
  alias AdminAPI.InviteEmail
  alias EWalletDB.Repo

  defp create_email(email, token) do
    invite = insert(:invite, %{token: token})
    _user  = insert(:admin, %{email: email, invite: invite})
    invite = Repo.preload(invite, :user)
    email  = InviteEmail.create(invite)

    email
  end

  describe "InviteEmail.create/1" do
    test "creates an email with correct from and to addresses" do
      email = create_email("test@omise.co", "the_token")

      # `from` should be the one set in the config
      config = Application.get_env(:admin_api, :email)
      assert email.from == config[:sender]

      # `to` should be the user's email
      assert email.to == "test@omise.co"
    end

    test "creates an email with non-empty subject" do
      email = create_email("test@omise.co", "the_token")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      email = create_email("test@omise.co", "the_token")

      assert email.html_body =~ "test@omise.co"
      assert email.html_body =~ "the_token"
    end

    test "creates an email with email and token in the text body" do
      email = create_email("test@omise.co", "the_token")

      assert email.text_body =~ "test@omise.co"
      assert email.text_body =~ "the_token"
    end
  end
end
