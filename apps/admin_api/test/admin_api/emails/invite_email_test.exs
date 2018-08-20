defmodule AdminAPI.InviteEmailTest do
  use AdminAPI.ConnCase
  alias AdminAPI.InviteEmail
  alias EWalletDB.Repo

  defp create_email(email, token) do
    invite = insert(:invite, %{token: token})
    _user = insert(:admin, %{email: email, invite: invite})
    invite = Repo.preload(invite, :user)
    email = InviteEmail.create(invite, "https://invite_url/?email={email}&token={token}")

    email
  end

  describe "InviteEmail.create/2" do
    test "creates an email with correct from and to addresses" do
      email = create_email("test@example.com", "the_token")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:ewallet, :sender_email)

      # `to` should be the user's email
      assert email.to == "test@example.com"
    end

    test "creates an email with non-empty subject" do
      email = create_email("test@example.com", "the_token")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      email = create_email("test@example.com", "the_token")
      assert email.html_body =~ "https://invite_url/?email=test%40example.com&token=the_token"
    end

    test "creates an email with email and token in the text body" do
      email = create_email("test@example.com", "the_token")
      assert email.text_body =~ "https://invite_url/?email=test%40example.com&token=the_token"
    end

    test "creates an email with properly encoded plus sign" do
      email = create_email("test+plus@example.com", "the_token")

      assert email.text_body =~
               "https://invite_url/?email=test%2Bplus%40example.com&token=the_token"
    end
  end
end
