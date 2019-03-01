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

defmodule AdminAPI.V1.SelfControllerTest do
  use AdminAPI.ConnCase, async: true
  use Bamboo.Test
  import Ecto.Query
  alias AdminAPI.UpdateEmailAddressEmail
  alias EWalletDB.{Account, Membership, Repo, User}
  alias EWalletDB.{Account, Membership, Repo, UpdateEmailRequest, User}
  alias Utils.Helpers.{Crypto, Assoc, DateFormatter}
  alias ActivityLogger.System
  alias EWalletConfig.Config

  @update_email_url "http://localhost:4000/update_email?email={email}&token={token}"

  describe "/me.get" do
    test "responds with user data" do
      response = admin_user_request("/me.get")

      assert response["success"]
      assert response["data"]["email"] == "email@example.com"
    end

    test "gets unauthorized back when requesting with a provider key" do
      response = provider_request("/me.get")

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/me.update" do
    test "update the current user with the given parameters" do
      response =
        admin_user_request("/me.update", %{
          metadata: %{"key" => "value_1337"},
          encrypted_metadata: %{"key" => "value_1337"}
        })

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["metadata"] == %{"key" => "value_1337"}
      assert response["data"]["encrypted_metadata"] == %{"key" => "value_1337"}
    end

    test "doesn't update params that are not provided" do
      user = get_test_admin()
      response = admin_user_request("/me.update", %{})

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["metadata"] == user.metadata
      assert response["data"]["encrypted_metadata"] == user.encrypted_metadata
    end

    test "ignore additional/invalid params" do
      user = get_test_admin()
      response = admin_user_request("/me.update", %{provider_user_id: "test_puid_1337"})

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["provider_user_id"] == user.provider_user_id
    end

    test "raise an error if the update is not valid" do
      response = admin_user_request("/me.update", %{metadata: "1234"})

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `metadata` is invalid."
    end

    test "gets unauthorized back when requesting with a provider key" do
      response =
        provider_request("/me.update", %{
          email: "test_1337@example.com",
          metadata: %{"key" => "value_1337"},
          encrypted_metadata: %{"key" => "value_1337"}
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/me.update", %{
          metadata: %{"key" => "value_1337"},
          encrypted_metadata: %{"key" => "value_1337"}
        })

      assert response["success"] == true

      admin = get_test_admin()
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: admin,
        target: admin,
        changes: %{
          "metadata" => %{"key" => "value_1337"}
        },
        encrypted_changes: %{
          "encrypted_metadata" => %{"key" => "value_1337"}
        }
      )
    end
  end

  describe "/me.update_password" do
    test "update the current user's password" do
      response =
        admin_user_request("/me.update_password", %{
          old_password: @password,
          password: "the_new_password",
          password_confirmation: "the_new_password"
        })

      assert response["success"] == true
      assert response["data"]["object"] == "user"

      user = User.get(@admin_id)
      assert Crypto.verify_password("the_new_password", user.password_hash)
      refute Crypto.verify_password(@password, user.password_hash)
    end

    test "returns error if the current password is invalid" do
      response =
        admin_user_request("/me.update_password", %{
          old_password: "wrong_old_password",
          password: "the_new_password",
          password_confirmation: "the_new_password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "user:invalid_old_password"

      assert response["data"]["description"] == "The provided old password is invalid."
    end

    test "returns error if the passwords do not match" do
      response =
        admin_user_request("/me.update_password", %{
          old_password: @password,
          password: "a_password",
          password_confirmation: "another_password"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password_confirmation` does not match password."
    end

    test "returns error if the password does not pass the requirements" do
      response =
        admin_user_request("/me.update_password", %{
          old_password: @password,
          password: "short",
          password_confirmation: "short"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` must be 8 characters or more."
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/me.update_password", %{
          old_password: @password,
          password: "the_new_password",
          password_confirmation: "the_new_password"
        })

      assert response["success"] == true

      admin = get_test_admin()
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: admin,
        target: admin,
        changes: %{
          "password_hash" => admin.password_hash
        },
        encrypted_changes: %{}
      )
    end

    test "gets unauthorized back when requesting with a provider key" do
      response =
        provider_request("/me.update_password", %{
          old_password: @password,
          password: "password",
          password_confirmation: "password"
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/me.update_email" do
    test "responds with user data with email unchanged" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test.update.email.unchanged@example.com",
          "redirect_url" => @update_email_url
        })

      assert response["success"]
      assert response["data"]["email"] == admin.email
      assert response["data"]["email"] != "test.update.email.unchanged@example.com"
    end

    test "sends a verification email" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test.sends.verification.email@example.com",
          "redirect_url" => @update_email_url
        })

      request =
        UpdateEmailRequest
        |> Repo.get_by(user_uuid: admin.uuid)
        |> Repo.preload(:user)

      assert response["success"]
      assert_delivered_email(UpdateEmailAddressEmail.create(request, @update_email_url))
    end

    test "returns an error when given email as nil" do
      response =
        admin_user_request("/me.update_email", %{
          "email" => nil,
          "redirect_url" => @update_email_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error if the email is not supplied" do
      response =
        admin_user_request("/me.update_email", %{
          "redirect_url" => @update_email_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error if the redirect_url is not supplied" do
      response =
        admin_user_request("/me.update_email", %{
          "email" => "test.redirect.url.not.supplied@example.com"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "gets unauthorized back when requesting with a provider key" do
      response =
        provider_request("/me.update_email", %{
          "email" => "test.email.update.provider.unauthorized@example.com",
          "redirect_url" => @update_email_url
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/me.update_email", %{
          "email" => "test.sends.verification.email@example.com",
          "redirect_url" => @update_email_url
        })

      assert response["success"] == true

      admin = get_test_admin()
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
          "email" => "test.sends.verification.email@example.com",
          "token" => request.token,
          "user_uuid" => admin.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/admin.verify_email_update" do
    test "returns success and updates the user's email" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

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
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

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
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

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
      {:ok, _request} = UpdateEmailRequest.generate(admin, new_email)

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
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

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
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: request.email
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "generates an activity log" do
      admin = get_test_admin()
      new_email = "test_email_update@example.com"
      {:ok, request} = UpdateEmailRequest.generate(admin, new_email)

      timestamp = DateTime.utc_now()

      response =
        unauthenticated_request("/admin.verify_email_update", %{
          email: new_email,
          token: request.token
        })

      assert response["success"] == true

      request = Repo.get_by(UpdateEmailRequest, user_uuid: admin.uuid)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: request,
        target: admin,
        changes: %{"email" => "test_email_update@example.com"},
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.upload_avatar" do
    test "uploads an avatar for the current user" do
      admin = get_test_admin()
      uuid = admin.id

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email

      assert response["data"]["avatar"]["large"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/large.png?v="

      assert response["data"]["avatar"]["original"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/original.jpg?v="

      assert response["data"]["avatar"]["small"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/small.png?v="

      assert response["data"]["avatar"]["thumb"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/thumb.png?v="
    end

    test "fails to upload avatar with GCS adapter and an invalid configuration", context do
      {:ok, _} =
        Config.update(
          %{
            file_storage_adapter: "gcs",
            gcs_bucket: "bucket",
            gcs_credentials: "123",
            originator: %System{}
          },
          context[:config_pid]
        )

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"] == false
      assert response["data"]["code"] == "adapter:server_not_running"
    end

    test "fails to upload an invalid file" do
      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/file.json",
            filename: "file.json"
          }
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error when 'avatar' is not sent" do
      response = admin_user_request("/me.upload_avatar", %{})

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "removes the avatar from the current user" do
      admin = get_test_admin()
      uuid = admin.id

      response =
        admin_user_request("/me.upload_avatar", %{
          "id" => uuid,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => nil
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from the current user with empty string" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => ""
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from the current user with 'null' string" do
      admin = get_test_admin()

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => "null"
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"] == true

      admin = get_test_admin()
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: admin,
        target: admin,
        changes: %{
          "avatar" => %{
            "file_name" => "test.jpg",
            "updated_at" => DateFormatter.to_iso8601(admin.avatar.updated_at)
          }
        },
        encrypted_changes: %{}
      )
    end

    test "gets unauthorized back when requesting with a provider key" do
      response =
        provider_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/me.get_account" do
    test "responds with an account" do
      account = User.get_account(get_test_admin())

      assert admin_user_request("/me.get_account") ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "account",
                   "id" => account.id,
                   "socket_topic" => "account:#{account.id}",
                   "parent_id" => Assoc.get(account, [:parent, :id]),
                   "name" => account.name,
                   "description" => account.description,
                   "master" => Account.master?(account),
                   "category_ids" => [],
                   "categories" => %{
                     "object" => "list",
                     "data" => []
                   },
                   "metadata" => %{},
                   "encrypted_metadata" => %{},
                   "avatar" => %{
                     "original" => nil,
                     "large" => nil,
                     "small" => nil,
                     "thumb" => nil
                   },
                   "created_at" => DateFormatter.to_iso8601(account.inserted_at),
                   "updated_at" => DateFormatter.to_iso8601(account.updated_at)
                 }
               }
    end

    test "responds with error if the user does not have an account" do
      user = get_test_admin()
      Repo.delete_all(from(m in Membership, where: m.user_uuid == ^user.uuid))

      assert admin_user_request("/me.get_account") ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "object" => "error",
                   "code" => "user:account_not_found",
                   "description" => "There is no account assigned to the provided user.",
                   "messages" => nil
                 }
               }
    end

    test "gets unauthorized back when requesting with a provider key" do
      response = provider_request("/me.get_account")

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/me.get_accounts" do
    test "responds with a list of accounts the current user belongs to" do
      admin = get_test_admin()

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      _account = insert(:account)

      # Clear all memberships for this user then add just one for precision
      Repo.delete_all(from(m in Membership, where: m.user_uuid == ^admin.uuid))

      {:ok, _} = Membership.assign(admin, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(admin, account_2, "admin", %System{})
      {:ok, _} = Membership.assign(admin, account_3, "admin", %System{})

      response = admin_user_request("/me.get_accounts")
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["id"] == account_1.id
      assert Enum.at(accounts, 1)["id"] == account_2.id
      assert Enum.at(accounts, 2)["id"] == account_3.id
    end

    test "gets unauthorized back when requesting with a provider key" do
      response = provider_request("/me.get_accounts")

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end
  end
end
