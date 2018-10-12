defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true
  import Bamboo.Test, only: [assert_delivered_email: 1]
  alias EWallet.Web.Preloader
  alias EWalletAPI.V1.VerifyEmailController
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.{Invite, User, Setting}

  describe "/user.signup" do
    test "returns success with an empty response" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "the_password",
          password_confirmation: "the_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "uses the default verification_url if not provided" do
      %{"success" => true} =
        client_request("/user.signup", %{
          email: "test_verfication_url@example.com",
          password: "the_password",
          password_confirmation: "the_password"
        })

      user = User.get_by(email: "test_verfication_url@example.com")
      {:ok, user} = Preloader.preload_one(user, :invite)

      assert_delivered_email(
        VerificationEmail.create(user.invite, VerifyEmailController.verify_url())
      )
    end

    test "uses the default success_url if not provided" do
      %{"success" => true} =
        client_request("/user.signup", %{
          email: "test_success_url@example.com",
          password: "the_password",
          password_confirmation: "the_password"
        })

      user = User.get_by(email: "test_success_url@example.com")
      {:ok, user} = Preloader.preload_one(user, :invite)

      assert user.invite.success_url == VerifyEmailController.success_url()
    end

    test "returns client:invalid_parameter when email is not provided" do
      response =
        client_request("/user.signup", %{
          password: "the_password",
          password_confirmation: "the_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test "returns client:invalid_parameter when password is not provided" do
      response =
        client_request("/user.signup", %{
          email: "test_no_password@example.com",
          password_confirmation: "the_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` must be 8 characters or more."
    end

    test "returns user:passwords_mismatch when passwords do not match" do
      response =
        client_request("/user.signup", %{
          email: "test_unmatch_password@example.com",
          password: "the_password",
          password_confirmation: "not_match"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:passwords_mismatch"
      assert response["data"]["description"] == "The provided passwords do not match."
    end
  end

  describe "verify_email/2" do
    setup do
      {:ok, user} =
        :standalone_user |> params_for(email: "verify_email@example.com") |> User.insert()

      {:ok, invite} = Invite.generate(user, preload: :user)

      %{
        user: invite.user,
        token: invite.token
      }
    end

    test "returns success with the user object", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token
        })

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "user"
      assert response["data"]["id"] == context.user.id
    end

    test "returns an error when email is invalid", context do
      response =
        client_request("/user.verify_email", %{
          email: "wrong.email@example.com",
          token: context.token
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:email_token_not_found"

      assert response["data"]["description"] ==
               "There is no pending email verification for the provided email and token."
    end

    test "returns an error when token is invalid", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: "wrong_token"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:email_token_not_found"

      assert response["data"]["description"] ==
               "There is no pending email verification for the provided email and token."
    end
  end
end
