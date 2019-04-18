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

defmodule AdminAPI.V1.TwoFactorAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.{TwoFactorAuthenticator}
  alias EWalletDB.{User}

  describe "/me.create_secret_code" do
    test "responds a new secret code if the authentication is valid" do
      response = admin_user_request("/me.create_secret_code", %{})

      assert %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "issuer" => "OmiseGO",
                 "label" => @user_email,
                 "secret_2fa_code" => secret_2fa_code,
                 "object" => "secret_code"
               }
             } = response

      assert secret_2fa_code != nil
    end

    test "responds error if the authentication is not valid" do
      response =
        admin_user_request("/me.create_secret_code", %{}, user_id: "1234", auth_token: "5678")

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "object" => "error",
                 "code" => "auth_token:not_found",
                 "description" => "There is no auth token corresponding to the provided token.",
                 "messages" => nil
               }
             }
    end
  end

  describe "/me.create_backup_codes" do
    test "responds new backup_codes if the authentication is valid" do
      response = admin_user_request("/me.create_backup_codes")

      assert response["success"] == true
      assert response["data"]["object"] == "backup_codes"
      assert length(response["data"]["backup_codes"]) > 0
    end

    test "responds error if the authentication is valid" do
      response =
        admin_user_request("/me.create_backup_codes", %{}, user_id: "1234", auth_token: "5678")

      assert response == %{
               "data" => %{
                 "code" => "auth_token:not_found",
                 "description" => "There is no auth token corresponding to the provided token.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end
  end

  describe "/me.enable_2fa" do
    test "responds authentication_token if the authentication is valid and the secret code has been created" do
      user = User.get(@admin_id)
      {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      passcode = generate_totp(attrs.secret_2fa_code)

      response = admin_user_request("/me.enable_2fa", %{"passcode" => passcode})

      assert response["success"] == true
      assert response["data"]["user"]["enabled_2fa_at"] != nil
      assert Map.has_key?(response["data"], "authentication_token")
    end

    test "create authorization header from the response should be able to access authenticated apis" do
      user = User.get(@admin_id)
      {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      passcode = generate_totp(attrs.secret_2fa_code)

      response = admin_user_request("/me.enable_2fa", %{"passcode" => passcode})
      assert response["success"] == true

      user_id = response["data"]["user_id"]
      auth_token = response["data"]["authentication_token"]

      response = admin_user_request("/wallet.all", %{}, user_id: user_id, auth_token: auth_token)
      assert response["success"] == true
    end

    test "responds error if given passcode is invalid" do
      user = User.get(@admin_id)
      {:ok, _} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      response = admin_user_request("/me.enable_2fa", %{"passcode" => "S3CR3T"})

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_passcode",
                 "description" => "The provided passcode is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error if the secret code has not been generated" do
      response = admin_user_request("/me.enable_2fa", %{"passcode" => "S3CR3T"})

      assert response == %{
               "data" => %{
                 "code" => "user:secret_code_not_found",
                 "description" => "The secret code could not be found.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end
  end

  describe "/me.disable_2fa" do
    test "responds authentication_token if the authentication is valid and the secret code has been created" do
      user = User.get(@admin_id)
      {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      passcode = generate_totp(attrs.secret_2fa_code)

      response = admin_user_request("/me.disable_2fa", %{"passcode" => passcode})

      assert response["success"] == true
      assert response["data"]["user"]["enabled_2fa_at"] == nil
      assert Map.has_key?(response["data"], "authentication_token")
    end

    test "responds error if given passcode is invalid" do
      user = User.get(@admin_id)
      {:ok, _} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      response = admin_user_request("/me.enable_2fa", %{"passcode" => "S3CR3T"})

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_passcode",
                 "description" => "The provided passcode is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error if the secret code has not been generated" do
      response = admin_user_request("/me.enable_2fa", %{"passcode" => "S3CR3T"})

      assert response == %{
               "data" => %{
                 "code" => "user:secret_code_not_found",
                 "description" => "The secret code could not be found.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end
  end

  describe "/2fa.verify_passcode" do
    test "create authorization header from the response should be able to access the authenticated apis" do
      user = User.get(@admin_id)

      {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)
      {:ok, auth_token} = TwoFactorAuthenticator.enable(user, nil, :admin_api, true)

      passcode = generate_totp(attrs.secret_2fa_code)

      response =
        admin_user_request("/2fa.verify_passcode", %{"passcode" => passcode},
          user_id: user.id,
          auth_token: auth_token.token
        )

      assert response["success"] == true

      response =
        admin_user_request("/wallet.all", %{}, user_id: user.id, auth_token: auth_token.token)

      assert response["success"] == true
    end
  end

  defp generate_totp(secret_code), do: :pot.totp(secret_code)
end
