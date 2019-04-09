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

defmodule AdminAPI.V1.TwoFactorAuthenticatorTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.TwoFactorAuthenticator
  alias EWalletDB.{User}
  alias Utils.Helpers.Crypto

  describe "verify" do
    test "returns {:ok} if the user has secret code and the given passcode is correct" do
      response = admin_user_request("/me.create_secret_code")
      secret_2fa_code = response["data"]["secret_2fa_code"]

      passcode = generate_totp(secret_2fa_code)
      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"passcode" => passcode}, user) == {:ok}
    end

    test "returns {:ok} if the user has hashed backup codes and the given backup code is correct" do
      response = admin_user_request("/me.create_backup_codes")

      [backup_code | _] = response["data"]["backup_codes"]
      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => backup_code}, user) == {:ok}
    end

    test "returns {:error, :invalid_passcode} if the user has secret code but the given passcode is incorrect" do
      admin_user_request("/me.create_secret_code")

      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, user) ==
               {:error, :invalid_passcode}
    end

    test "returns {:error, :invalid_backup_code} if the user has secret code but the given passcode is incorrect" do
      admin_user_request("/me.create_backup_codes")

      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => "／人 ◕ ‿‿ ◕ 人＼"}, user) ==
               {:error, :invalid_backup_code}
    end

    test "returns {:error, :secret_code_not_found} if the user's secret code is nil" do
      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, user) ==
               {:error, :secret_code_not_found}
    end

    test "returns {:error, :backup_codes_not_found} if the user's hashed backup codes is nil" do
      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => "／人 ◕ ‿‿ ◕ 人＼"}, user) ==
               {:error, :backup_codes_not_found}
    end

    test "returns {:error, :invalid_parameter} if attributes are not matched" do
      user = User.get_by_email(@user_email)

      assert TwoFactorAuthenticator.verify(%{"sms_otp" => "¬_¬"}, user) ==
               {:error, :invalid_parameter}
    end

    test "returns {:error, :invalid_parameter} if the user is nil" do
      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, nil) ==
               {:error, :invalid_parameter}
    end
  end

  describe "create_and_update" do
    test "returns {:ok, secret_code_attrs} when given :secret_code" do
      user = User.get_by_email(@user_email)
      assert {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      updated_user = User.get_by_email(@user_email)

      assert attrs == %{
               issuer: "OmiseGO",
               label: @user_email,
               secret_2fa_code: updated_user.secret_2fa_code
             }
    end

    test "returns {:ok, backup_codes_attrs} when given :backup_codes" do
      user = User.get_by_email(@user_email)
      assert {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :backup_codes)

      updated_user = User.get_by_email(@user_email)

      assert length(attrs.backup_codes) == 10

      assert Enum.all?(
               attrs.backup_codes,
               &verify_backup_code(&1, updated_user.hashed_backup_codes)
             )
    end

    defp verify_backup_code(backup_code, hashed_backup_codes) do
      Enum.any?(hashed_backup_codes, fn hashed_backup_code ->
        Crypto.verify_password(backup_code, hashed_backup_code)
      end)
    end
  end

  describe "enable" do
    test "returns an auth token with required_2fa: false" do
      user = User.get_by_email(@user_email)

      # Verify the enable_2fa response should indicate required_2fa: false
      assert {:ok, auth_token} = TwoFactorAuthenticator.enable(user, nil, :admin_api, true)
      assert auth_token.required_2fa == false
    end

    test "a request with pre-enabled-2fa authorization should not be allowed to access authenticated apis" do
      user = User.get_by_email(@user_email)

      TwoFactorAuthenticator.enable(user, nil, :admin_api, true)

      # Verify authenticated API with pre-enabled-2fa token should not be successful
      response = admin_user_request("/wallet.all")
      assert response["success"] == false
    end

    test "login api should return an auth token with required_2fa: true" do
      user = User.get_by_email(@user_email)

      TwoFactorAuthenticator.enable(user, nil, :admin_api, true)

      # Verify login response should indicate required_2fa: true
      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      assert response["data"]["required_2fa"] == true
    end
  end

  defp generate_totp(secret_code), do: :pot.totp(secret_code)
end
