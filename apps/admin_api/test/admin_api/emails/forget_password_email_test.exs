defmodule AdminAPI.ForgetPasswordEmailTest do
  use AdminAPI.ConnCase
  alias AdminAPI.ForgetPasswordEmail
  alias EWalletDB.ForgetPasswordRequest

  defp create_email(email, token) do
    user = insert(:user, email: email)
    _request = insert(:forget_password_request, token: token, user_uuid: user.uuid)
    request = ForgetPasswordRequest.get(user, token)
    email = ForgetPasswordEmail.create(request, "https://reset_url/?email={email}&token={token}")

    email
  end

  describe "ForgetPasswordEmail.create/2" do
    test "creates an email with correct from and to addresses" do
      email = create_email("forgetpassword@example.com", "the_token")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:admin_api, :sender_email)

      # `to` should be the user's email
      assert email.to == "forgetpassword@example.com"
    end

    test "creates an email with non-empty subject" do
      email = create_email("forgetpassword@example.com", "the_token")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      email = create_email("forgetpassword@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=forgetpassword%40example.com&token=the_token"
    end

    test "creates an email with email and token in the text body" do
      email = create_email("forgetpassword@example.com", "the_token")

      assert email.text_body =~
               "https://reset_url/?email=forgetpassword%40example.com&token=the_token"
    end

    test "creates an email with properly encoded plus sign" do
      email = create_email("forgetpassword+test@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=forgetpassword%2Btest%40example.com&token=the_token"
    end
  end
end
