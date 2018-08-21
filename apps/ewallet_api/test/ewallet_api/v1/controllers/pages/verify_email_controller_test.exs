defmodule EWalletAPI.V1.VerifyEmailControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "verify/2" do
    defp verify_email(email, token) do
      build_conn()
      |> get("/pages/client/v1/verify_email?email=#{email}&token=#{token}")
    end

    test "redirects to the invite.success_url on success" do
      invite = insert(:invite, success_url: "https://example.com/success_url")
      user = insert(:standalone_user, %{invite: invite})
      conn = verify_email(user.email, invite.token)

      assert redirected_to(conn) == "https://example.com/success_url"
    end

    test "redirects to the default success_url when invite.success_url is not given" do
      invite = insert(:invite)
      user = insert(:standalone_user, %{invite: invite})
      conn = verify_email(user.email, invite.token)

      assert redirected_to(conn) == "/pages/client/v1/verify_email/success"
    end

    test "returns an error when the email is invalid" do
      invite = insert(:invite)
      _user = insert(:standalone_user, %{invite: invite})
      response = verify_email("wrong@example.com", invite.token) |> text_response(:ok)

      assert response == "Unable to verify your email address. There is no pending email verification for the provided email and token."
    end

    test "returns an error when the token is invalid" do
      invite = insert(:invite)
      user = insert(:standalone_user, %{invite: invite})
      response = verify_email(user.email, "wrong_token") |> text_response(:ok)

      assert response == "Unable to verify your email address. There is no pending email verification for the provided email and token."
    end
  end

  describe "success/2" do
    test "returns the success text" do
      response =
        build_conn()
        |> get("/pages/client/v1/verify_email/success")
        |> text_response(:ok)

      assert response == "Your email address is successfully verified!"
    end
  end
end
