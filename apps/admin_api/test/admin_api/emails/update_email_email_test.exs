defmodule AdminAPI.UpdateEmailAddressEmailTest do
  use AdminAPI.ConnCase
  alias AdminAPI.UpdateEmailAddressEmail
  alias EWalletDB.UpdateEmailRequest

  defp create_email(email_address, token) do
    user = insert(:user)

    _request =
      insert(:update_email_request, email: email_address, token: token, user_uuid: user.uuid)

    request = UpdateEmailRequest.get(email_address, token)
    email = UpdateEmailAddressEmail.create(request, "https://reset_url/?email={email}&token={token}")

    email
  end

  describe "ForgetPasswordEmail.create/2" do
    test "creates an email with correct from and to addresses" do
      email = create_email("test_update_email@example.com", "the_token")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:ewallet, :sender_email)

      # `to` should be the user's new email
      assert email.to == "test_update_email@example.com"
    end

    test "creates an email with non-empty subject" do
      email = create_email("test_update_email@example.com", "the_token")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      email = create_email("test_update_email@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=test_update_email%40example.com&token=the_token"
    end

    test "creates an email with email and token in the text body" do
      email = create_email("test_update_email@example.com", "the_token")

      assert email.text_body =~
               "https://reset_url/?email=test_update_email%40example.com&token=the_token"
    end

    test "creates an email with properly encoded plus sign" do
      email = create_email("test_update_email+test@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=test_update_email%2Btest%40example.com&token=the_token"
    end
  end
end
