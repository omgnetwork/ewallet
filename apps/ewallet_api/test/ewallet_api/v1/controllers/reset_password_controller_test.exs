# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletAPI.V1.ResetPasswordControllerTest do
  use EWalletAPI.ConnCase, async: true
  use Bamboo.Test
  alias EWallet.ForgetPasswordEmail
  alias Utils.Helpers.{Crypto, DateFormatter}
  alias EWalletDB.{ForgetPasswordRequest, Repo, User}

  @redirect_url "http://localhost:4000/reset_password?email={email}&token={token}"

  describe "ResetPasswordController.reset/2" do
    test "returns success if the request was generated successfully" do
      {:ok, user} = :admin |> params_for() |> User.insert()

      response =
        public_request("/user.reset_password", %{
          "email" => user.email,
          "redirect_url" => @redirect_url
        })

      request =
        ForgetPasswordRequest
        |> Repo.get_by(user_uuid: user.uuid)
        |> Repo.preload(:user)

      assert response["success"]
      assert_delivered_email(ForgetPasswordEmail.create(request, @redirect_url))
      assert request != nil
      assert request.token != nil
    end

    test "returns client:invalid_parameter error if the redirect_url is not allowed" do
      redirect_url = "http://unknown-url.com/reset_password?email={email}&token={token}"

      response =
        public_request("/user.reset_password", %{
          "email" => "example@mail.com",
          "redirect_url" => redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "The given `redirect_url` is not allowed. Got: '#{redirect_url}'."
    end

    test "returns an error when sending email = nil" do
      response =
        public_request("/user.reset_password", %{
          "email" => nil,
          "redirect_url" => @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns a success without a new request, when the given email is not found" do
      num_requests = Repo.aggregate(ForgetPasswordRequest, :count, :token)

      response =
        public_request("/user.reset_password", %{
          "email" => "example@mail.com",
          "redirect_url" => @redirect_url
        })

      assert response["success"] == true
      assert Repo.aggregate(ForgetPasswordRequest, :count, :token) == num_requests
    end

    test "returns an error if the email is not supplied" do
      {:ok, user} = :admin |> params_for() |> User.insert()

      response =
        public_request("/user.reset_password", %{
          "redirect_url" => @redirect_url
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
      {:ok, user} = :admin |> params_for() |> User.insert()

      response =
        public_request("/user.reset_password", %{
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

    test "generates an activity log" do
      {:ok, user} = :admin |> params_for() |> User.insert()

      timestamp = DateTime.utc_now()

      response =
        public_request("/user.reset_password", %{
          "email" => user.email,
          "redirect_url" => @redirect_url
        })

      request =
        ForgetPasswordRequest
        |> Repo.get_by(user_uuid: user.uuid)
        |> Repo.preload(:user)

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: :system,
        target: request,
        changes: %{
          "expires_at" => DateFormatter.to_iso8601(request.expires_at),
          "token" => request.token,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "ResetPasswordController.update/2" do
    test "returns success and updates the password if the password has been reset succesfully" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, request} = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        public_request("/user.update_password", %{
          email: user.email,
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"]
      user = User.get(user.id)
      assert Crypto.verify_password("password", user.password_hash)
      assert ForgetPasswordRequest.all_active() |> length() == 0
    end

    test "returns a token_not_found error when the user is not found" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, request} = ForgetPasswordRequest.generate(user)

      response =
        public_request("/user.update_password", %{
          email: "example@mail.com",
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "forget_password:token_not_found"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "returns a token_not_found error when the request is not found" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      _request = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        public_request("/user.update_password", %{
          email: user.email,
          token: "123",
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "forget_password:token_not_found"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "returns a client:invalid_parameter error when the password is too short" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, request} = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        public_request("/user.update_password", %{
          email: user.email,
          token: request.token,
          password: "short",
          password_confirmation: "short"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` must be 8 characters or more."

      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "returns an invalid parameter error when the email is not sent" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, request} = ForgetPasswordRequest.generate(user)

      assert user.password_hash != Crypto.hash_password("password")

      response =
        public_request("/user.update_password", %{
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert ForgetPasswordRequest |> Repo.all() |> length() == 1
    end

    test "generates an activity log" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, request} = ForgetPasswordRequest.generate(user)

      timestamp = DateTime.utc_now()

      response =
        public_request("/user.update_password", %{
          email: user.email,
          token: request.token,
          password: "password",
          password_confirmation: "password"
        })

      assert response["success"] == true

      user = User.get(user.id)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: request,
        target: user,
        changes: %{"password_hash" => user.password_hash},
        encrypted_changes: %{}
      )
    end
  end
end
