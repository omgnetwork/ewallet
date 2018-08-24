defmodule EWalletAPI.VerificationEmailTest do
  use EWalletAPI.ConnCase
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.Invite

  defp create_email(email) do
    user = insert(:standalone_user, email: email)
    {:ok, invite} = Invite.generate(user)

    {VerificationEmail.create(invite, "https://invite_url/?email={email}&token={token}"),
     invite.token}
  end

  describe "create/2" do
    test "creates an email with correct from and to addresses" do
      {email, _token} = create_email("test@example.com")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:ewallet, :sender_email)

      # `to` should be the user's email
      assert email.to == "test@example.com"
    end

    test "creates an email with non-empty subject" do
      {email, _token} = create_email("test@example.com")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      {email, token} = create_email("test@example.com")
      assert email.html_body =~ "https://invite_url/?email=test@example.com&token=#{token}"
    end

    test "creates an email with email and token in the text body" do
      {email, token} = create_email("test@example.com")
      assert email.text_body =~ "https://invite_url/?email=test@example.com&token=#{token}"
    end
  end
end
