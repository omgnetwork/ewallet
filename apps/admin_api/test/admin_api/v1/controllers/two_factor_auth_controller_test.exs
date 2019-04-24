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
  alias EWallet.Web.V1.UserSerializer
  alias EWallet.{TwoFactorAuthenticator}
  alias EWalletDB.{User, Repo, AuthToken, PreAuthToken}

  describe "/me.create_secret_code" do
    test "responds a new secret code if the authorization header is valid" do
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

    test "responds error if the authorization header is invalid" do
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
    test "responds new backup_codes if the authorization header is valid" do
      response = admin_user_request("/me.create_backup_codes")

      assert response["success"] == true
      assert response["data"]["object"] == "backup_codes"
      assert length(response["data"]["backup_codes"]) > 0
    end

    test "responds error if the authorization header is invalid" do
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
    test "responds success if the given both passcode and backup_code are valid" do
      user = User.get(@admin_id)

      {%{backup_codes: [backup_code | _]}, _} = create_backup_codes(user)
      {%{secret_2fa_code: secret_2fa_code}, _} = create_secret_code(user)

      passcode = generate_totp(secret_2fa_code)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => passcode,
          "backup_code" => backup_code
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "responds error auth_token:not_found if continue using the old authentication token" do
      user = User.get(@admin_id)

      {%{backup_codes: [backup_code | _]}, _} = create_backup_codes(user)
      {%{secret_2fa_code: secret_2fa_code}, _} = create_secret_code(user)

      passcode = generate_totp(secret_2fa_code)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => passcode,
          "backup_code" => backup_code
        })

      assert response == %{"data" => %{}, "success" => true, "version" => "1"}

      response = admin_user_request("/wallet.all", %{})

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

    test "responds error user:invalid_parameter if the passcode is not provided" do
      response =
        admin_user_request("/me.enable_2fa", %{
          "backup_code" => "12345678"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `passcode` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:invalid_parameter if the backup_code is not provided" do
      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => "123456"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `backup_code` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:invalid_passcode if given passcode is invalid" do
      user = User.get(@admin_id)

      create_secret_code(user)
      {%{backup_codes: [backup_code | _]}, _} = create_backup_codes(user)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => "S3CR3T",
          "backup_code" => backup_code
        })

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_passcode",
                 "description" => "The provided `passcode` is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:invalid_backup_code if given backup_code is invalid" do
      user = User.get(@admin_id)

      {attrs, _} = create_secret_code(user)
      create_backup_codes(user)

      passcode = generate_totp(attrs.secret_2fa_code)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => passcode,
          "backup_code" => "12345678"
        })

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_backup_code",
                 "description" => "The provided `backup_code` is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:secret_code_not_found if the secret code has not been generated" do
      user = User.get(@admin_id)

      {%{backup_codes: [backup_code | _]}, _} = create_backup_codes(user)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => "S3CR3T",
          "backup_code" => backup_code
        })

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

    test "responds error user:backup_codes_not_found if the backup codes have not been generated" do
      user = User.get(@admin_id)

      {%{secret_2fa_code: secret_2fa_code}, _} = create_secret_code(user)

      passcode = generate_totp(secret_2fa_code)

      response =
        admin_user_request("/me.enable_2fa", %{
          "passcode" => passcode,
          "backup_code" => "12345678"
        })

      assert response == %{
               "data" => %{
                 "code" => "user:backup_codes_not_found",
                 "description" => "The backup codes could not be found.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end
  end

  describe "/me.disable_2fa" do
    test "responds success if the given passcode is valid" do
      user = User.get(@admin_id)

      {_, secret_2fa_code, _} = create_two_factors_and_enable_2fa(user)

      passcode = generate_totp(secret_2fa_code)

      response = login_two_steps(user, %{passcode: passcode})

      response =
        admin_user_request("/me.disable_2fa", %{"passcode" => passcode},
          user_id: @admin_id,
          auth_token: response["data"]["authentication_token"]
        )

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "responds success if the given backup_code is valid" do
      user = User.get(@admin_id)

      {[backup_code | _], _, _} = create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{backup_code: backup_code})

      response =
        admin_user_request("/me.disable_2fa", %{"backup_code" => backup_code},
          user_id: @admin_id,
          auth_token: response["data"]["authentication_token"]
        )

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "responds error client:invalid_parameter if the required params are missing" do
      user = User.get(@admin_id)

      {_, secret_2fa_code, _} = create_two_factors_and_enable_2fa(user)

      passcode = generate_totp(secret_2fa_code)

      response = login_two_steps(user, %{passcode: passcode})

      response =
        admin_user_request("/me.disable_2fa", %{},
          user_id: @admin_id,
          auth_token: response["data"]["authentication_token"]
        )

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" =>
                   "Invalid parameter provided. `backup_code` or `passcode` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:invalid_passcode if given passcode is invalid" do
      user = User.get(@admin_id)

      create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{passcode: "1234567"})

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_passcode",
                 "description" => "The provided `passcode` is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error user:secret_code_not_found if the secret code has not been generated" do
      response = admin_user_request("/me.disable_2fa", %{"passcode" => "S3CR3T"})

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

  describe "/admin.login_2fa" do
    test "responds success on valid passcode" do
      user = User.get(@admin_id)

      {_, secret_2fa_code, _} = create_two_factors_and_enable_2fa(user)

      passcode = generate_totp(secret_2fa_code)

      response = login_two_steps(user, %{passcode: passcode})

      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])

      assert response == %{
               "version" => @expected_version,
               "success" => true,
               "data" => %{
                 "object" => "authentication_token",
                 "authentication_token" => auth_token.token,
                 "user_id" => auth_token.user.id,
                 "user" => auth_token.user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "master_admin" => nil,
                 "role" => nil,
                 "global_role" => auth_token.user.global_role
               }
             }

      # Ensure a pre authentication token has been deleted after login two-factor successfully.
      pre_auth_token = PreAuthToken |> get_last_inserted() |> Repo.preload([:user, :account])
      assert pre_auth_token == nil
    end

    test "responds success on valid backup_code" do
      user = User.get(@admin_id)

      {[backup_code | _], _, _} = create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{backup_code: backup_code})

      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])

      assert response == %{
               "version" => @expected_version,
               "success" => true,
               "data" => %{
                 "object" => "authentication_token",
                 "authentication_token" => auth_token.token,
                 "user_id" => auth_token.user.id,
                 "user" => auth_token.user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "master_admin" => nil,
                 "role" => nil,
                 "global_role" => auth_token.user.global_role
               }
             }

      # Ensure a pre authentication token has been deleted after login two-factor successfully.
      pre_auth_token = PreAuthToken |> get_last_inserted() |> Repo.preload([:user, :account])
      assert pre_auth_token == nil
    end

    test "responds success when access authenticated apis with new authentication header" do
      user = User.get(@admin_id)

      {_, secret_2fa_code, _} = create_two_factors_and_enable_2fa(user)

      passcode = generate_totp(secret_2fa_code)

      response = login_two_steps(user, %{passcode: passcode})

      assert response["success"] == true
      assert auth_token = response["data"]["authentication_token"]

      response = admin_user_request("/wallet.all", %{}, user_id: user.id, auth_token: auth_token)
      assert response["success"] == true
    end

    test "responds error when access authenticated apis with old authentication header" do
      user = User.get(@admin_id)

      create_two_factors_and_enable_2fa(user)

      response = admin_user_request("/wallet.all", %{})

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

    test "responds error when the two-factor authentication has not been enabled" do
      user = User.get(@admin_id)

      {%{secret_2fa_code: secret_2fa_code}, _} = create_secret_code(user)
      create_backup_codes(user)

      passcode = generate_totp(secret_2fa_code)

      response = admin_user_request("/admin.login_2fa", %{"passcode" => passcode})

      assert response == %{
               "data" => %{
                 "code" => "user:2fa_disabled",
                 "description" => "This user has not enabled two-factor authentication.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error when the given passcode is invalid" do
      user = User.get(@admin_id)

      create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{passcode: "123456"})

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_passcode",
                 "description" => "The provided `passcode` is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error when the give backup_code is invalid" do
      user = User.get(@admin_id)

      create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{backup_code: "12345678"})

      assert response == %{
               "data" => %{
                 "code" => "user:invalid_backup_code",
                 "description" => "The provided `backup_code` is invalid.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "responds error when required params are missing" do
      user = User.get(@admin_id)

      create_two_factors_and_enable_2fa(user)

      response = login_two_steps(user, %{})

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "messages" => nil,
                 "object" => "error",
                 "code" => "client:invalid_parameter",
                 "description" =>
                   "Invalid parameter provided. `backup_code` or `passcode` is required."
               }
             }
    end
  end

  defp create_two_factors_and_enable_2fa(user) do
    {secret_attrs, _} = create_secret_code(user)
    {backup_attrs, created_backup_codes_user} = create_backup_codes(user)

    {:ok} = TwoFactorAuthenticator.enable(created_backup_codes_user, :admin_api)

    {backup_attrs.backup_codes, secret_attrs.secret_2fa_code, User.get(user.id)}
  end

  defp login_two_steps(user, attrs) do
    response = unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

    pre_auth_token = response["data"]["pre_authentication_token"]

    response =
      admin_user_request("/admin.login_2fa", attrs,
        user_id: user.id,
        auth_token: pre_auth_token
      )

    response
  end

  defp create_backup_codes(user) do
    {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :backup_codes)

    created_backup_codes_user = User.get(user.id)

    {attrs, created_backup_codes_user}
  end

  defp create_secret_code(user) do
    {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

    created_secret_code_user = User.get(user.id)

    {attrs, created_secret_code_user}
  end

  defp generate_totp(secret_code), do: :pot.totp(secret_code)
end
