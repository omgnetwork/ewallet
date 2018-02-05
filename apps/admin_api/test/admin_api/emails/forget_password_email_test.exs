defmodule AdminAPI.ForgetPasswordEmailTest do
  use AdminAPI.ConnCase
  alias AdminAPI.ForgetPasswordEmail
  alias EWalletDB.ForgetPasswordRequest

  setup do
    user     = insert(:user, email: "example@mail.com")
    _request = insert(:forget_password_request, token: "the_token", user_id: user.id)
    request  = ForgetPasswordRequest.get(user, "the_token")
    email    = ForgetPasswordEmail.create(request, "https://reset_url/?email={email}&token={token}")

    %{user: user, request: request, email: email}
  end

  describe "ForgetPasswordEmail.create/2" do
    test "creates an email with correct from and to addresses", meta do
      # `from` should be the one set in the config
      assert meta.email.from == Application.get_env(:admin_api, :sender_email)

      # `to` should be the user's email
      assert meta.email.to == meta.user.email
    end

    test "creates an email with non-empty subject", meta do
      assert String.length(meta.email.subject) > 0
    end

    test "creates an email with email and token in the html body", meta do
      assert meta.email.html_body =~ "https://reset_url/?email=example@mail.com&token=the_token"
    end

    test "creates an email with email and token in the text body", meta do
      assert meta.email.text_body =~ "https://reset_url/?email=example@mail.com&token=the_token"
    end
  end
end
