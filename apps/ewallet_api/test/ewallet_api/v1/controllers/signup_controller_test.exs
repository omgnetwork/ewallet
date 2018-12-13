defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true
  import Bamboo.Test, only: [assert_delivered_email: 1]
  alias EWallet.Web.Preloader
  alias EWalletAPI.V1.VerifyEmailController
  alias EWallet.VerificationEmail
  alias EWalletDB.{Invite, User, AccountUser, Repo}
  alias ActivityLogger.System

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

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "the_password",
          password_confirmation: "the_password"
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      user = get_last_inserted(User)
      invite = get_last_inserted(Invite)
      wallet = User.get_primary_wallet(user)
      account_user = get_last_inserted(AccountUser)
      assert Enum.count(logs) == 5

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: wallet,
        changes: %{
          "identifier" => "primary",
          "name" => "primary",
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: user,
        changes: %{
          "email" => "test_user_signup@example.com",
          "password_hash" => user.password_hash
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "update",
        originator: invite,
        target: user,
        changes: %{"invite_uuid" => invite.uuid},
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: invite,
        changes: %{
          "success_url" => "http://localhost:4000/pages/client/v1/verify_email/success",
          "token" => invite.token,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(4)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: account_user,
        changes: %{
          "account_uuid" => account_user.account_uuid,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "verify_email/2" do
    setup do
      {:ok, user} =
        :standalone_user |> params_for(email: "verify_email@example.com") |> User.insert()

      {:ok, invite} = Invite.generate(user, %System{}, preload: :user)

      %{
        user: invite.user,
        token: invite.token,
        invite: invite
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

    test "generates an activity log", context do
      timestamp = DateTime.utc_now()

      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)

      invite = Repo.get_by(Invite, uuid: context.invite.uuid)
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: context.user,
        target: context.user,
        changes: %{"invite_uuid" => nil},
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: context.user,
        target: invite,
        changes: %{"verified_at" => NaiveDateTime.to_iso8601(invite.verified_at)},
        encrypted_changes: %{}
      )
    end
  end
end
