# Copyright 2018 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.AdminAuth.UpdateEmailControllerTest do
  use AdminAPI.ConnCase, async: true
  use Bamboo.Test
  alias AdminAPI.UpdateEmailAddressEmail
  alias EWalletDB.{UpdateEmailRequest, Repo, User}

  @redirect_url "http://localhost:4000/update_email?email={email}&token={token}"

  describe "/me.update_email" do
    test "responds with user data with email unchanged" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test_email_update@example.com",
          "redirect_url" => @redirect_url
        })

      assert response["success"]
      assert response["data"]["email"] == admin.email
      assert response["data"]["email"] != "test_email_update@example.com"
    end

    test "sends a verification email" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test_email_update@example.com",
          "redirect_url" => @redirect_url
        })

      request =
        UpdateEmailRequest
        |> Repo.get_by(user_uuid: admin.uuid)
        |> Repo.preload(:user)

      assert response["success"]
      assert_delivered_email(UpdateEmailAddressEmail.create(request, @redirect_url))
    end

    test "returns client:invalid_parameter error if the redirect_url is not allowed" do
      redirect_url = "http://unknown-url.com/update_email?email={email}&token={token}"

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test_email_update@example.com",
          "redirect_url" => redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "The given `redirect_url` is not allowed. Got: '#{redirect_url}'."
    end

    test "returns an error when sending email = nil" do
      response =
        admin_user_request("/me.update_email", %{
          "email" => nil,
          "redirect_url" => @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error if the email is not supplied" do
      response =
        admin_user_request("/me.update_email", %{
          "redirect_url" => @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error if the redirect_url is not supplied" do
      response =
        admin_user_request("/me.update_email", %{
          "email" => "test_update_email@example.com"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error if there is already a user with the associated email" do
      another_admin = insert(:admin)

      response =
        admin_user_request("/me.update_email", %{
          "email" => another_admin.email,
          "redirect_url" => @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "user:email_already_exists"
    end

    test "generates activity logs" do
      admin = get_test_admin()
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test_email_update@example.com",
          "redirect_url" => @redirect_url
        })

      assert response["success"] == true

      request = Repo.get_by(UpdateEmailRequest, user_uuid: admin.uuid)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: admin,
        target: request,
        changes: %{
          "email" => "test_email_update@example.com",
          "token" => request.token,
          "user_uuid" => admin.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.update_email_verification" do
    test "returns success and updates the user's email" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      # Make sure the email is not the same
      assert admin.email != new_email

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: new_email,
          token: request.token
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.email == new_email
      assert UpdateEmailRequest.all_active() |> length() == 0
    end

    test "returns an email_already_exists error when the email is used by another user" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      # Meanwhile, another admin has also been created with the new email.
      _ = insert(:admin, email: new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: new_email,
          token: request.token
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `email` has already been taken."
    end

    test "returns a token_not_found error when the email is invalid" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: "invalid_email@example.com",
          token: request.token
        })

      assert response["success"] == false
      assert response["data"]["code"] == "email_update:token_not_found"

      assert response["data"]["description"] ==
               "There are no email update requests corresponding to the provided token."
    end

    test "returns a token_not_found error when the token is invalid" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      _request = UpdateEmailRequest.generate(admin, new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: new_email,
          token: "invalid_token"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "email_update:token_not_found"

      assert response["data"]["description"] ==
               "There are no email update requests corresponding to the provided token."
    end

    test "returns an invalid parameter error when the email is not given" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          token: request.token
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns an invalid parameter error when the token is not given" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: request.email
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "generates activity logs" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      request = UpdateEmailRequest.generate(admin, new_email)

      timestamp = DateTime.utc_now()

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: new_email,
          token: request.token
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: request,
        target: admin,
        changes: %{
          "email" => "test_email_update@example.com"
        },
        encrypted_changes: %{}
      )
    end
  end
end
