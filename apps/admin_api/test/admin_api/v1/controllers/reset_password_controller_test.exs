defmodule AdminAPI.V1.ResetPasswordControllerTest do
  use AdminAPI.ConnCase, async: true
  use Bamboo.Test
  alias EWalletDB.{Repo, ForgetPasswordRequest, User, Helpers.Crypto}
  alias AdminAPI.ForgetPasswordEmail

  describe "ResetPasswordController.reset/2" do
    test "returns success if the request was generated successfully" do
      user = insert(:admin)

      response =
        client_request("/password.reset", %{
          "email" => user.email,
          "redirect_url" => "http://example.com"
        })

      request =
        ForgetPasswordRequest
        |> Repo.get_by(user_uuid: user.uuid)
        |> Repo.preload(:user)

      assert response["success"]
      assert_delivered_email(ForgetPasswordEmail.create(request, "http://example.com"))
      assert request != nil
      assert request.token != nil
    end

    test "returns an error if no user is found with the associated email" do
      response =
        client_request("/password.reset", %{
          "email" => "example@mail.com",
          "redirect_url" => "http://example.com"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "user:email_not_found"
    end

    test "returns an error if the email is not supplied" do
      user = insert(:admin)

      response =
        client_request("/password.reset", %{
          "redirect_url" => "http://example.com"
        })

      request =
        ForgetPasswordRequest
        |> Repo.get_by(user_uuid: user.uuid)
        |> Repo.preload(:user)

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert request == nil
    end

    test "returns an error if the redirect_url is not supplied" do
      user = insert(:admin)

      response =
        client_request("/password.reset", %{
          "email" => user.email
        })

      request =
        ForgetPasswordRequest
        |> Repo.get_by(user_uuid: user.uuid)
        |> Repo.preload(:user)

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert request == nil
    end
  end

  describe "ResetPasswordController.update/2" do
    test "returns success and updates the password if the password has been reset succesfully" do
      user = insert(:admin)
      request = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        client_request("/password.update", %{
          email: user.email,
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"]
      user = User.get(user.id)
      assert Crypto.verify_password("password", user.password_hash)
      assert ForgetPasswordRequest |> Repo.all() |> length() == 0
    end

    test "returns an email_not_found error when the user is not found" do
      user = insert(:admin)
      request = ForgetPasswordRequest.generate(user)

      response =
        client_request("/password.update", %{
          email: "example@mail.com",
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "user:email_not_found"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "returns a token_not_found error when the request is not found" do
      user = insert(:admin)
      _request = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        client_request("/password.update", %{
          email: user.email,
          token: "123",
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "forget_password:token_not_found"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "returns an invalid parameter error when the email is not sent" do
      user = insert(:admin)
      request = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        client_request("/password.update", %{
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end
  end
end
