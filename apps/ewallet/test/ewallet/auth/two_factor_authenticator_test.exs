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

defmodule EWallet.TwoFactorAuthenticatorTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TwoFactorAuthenticator
  alias EWalletDB.{User, AuthToken}
  alias Utils.Helpers.Crypto

  describe "verify" do
    test "returns {:ok} if the user has secret code and the given passcode is correct" do
      user = insert(:user)

      {:ok, %{secret_2fa_code: secret_2fa_code}} =
        TwoFactorAuthenticator.create_and_update(user, :secret_code)

      updated_user = User.get(user.id)

      passcode = generate_totp(secret_2fa_code)
      assert TwoFactorAuthenticator.verify(%{"passcode" => passcode}, updated_user) == {:ok}
    end

    test "returns {:ok} if the user has hashed backup codes and the given backup code is correct" do
      user = insert(:user)

      {:ok, %{backup_codes: [backup_code | _]}} =
        TwoFactorAuthenticator.create_and_update(user, :backup_codes)

      updated_user = User.get(user.id)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => backup_code}, updated_user) == {:ok}
    end

    test "returns {:error, :invalid_passcode} if the user has secret code but the given passcode is incorrect" do
      user = insert(:user)

      TwoFactorAuthenticator.create_and_update(user, :secret_code)

      updated_user = User.get(user.id)

      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, updated_user) ==
               {:error, :invalid_passcode}
    end

    test "returns {:error, :invalid_backup_code} if the user has secret code but the given passcode is incorrect" do
      user = insert(:user)

      TwoFactorAuthenticator.create_and_update(user, :backup_codes, %{number_of_backup_codes: 1})

      updated_user = User.get(user.id)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => "／人 ◕ ‿‿ ◕ 人＼"}, updated_user) ==
               {:error, :invalid_backup_code}
    end

    test "returns {:error, :secret_code_not_found} if the user's secret code is nil" do
      user = insert(:user)

      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, user) ==
               {:error, :secret_code_not_found}
    end

    test "returns {:error, :backup_codes_not_found} if the user's hashed backup codes is nil" do
      user = insert(:user)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => "／人 ◕ ‿‿ ◕ 人＼"}, user) ==
               {:error, :backup_codes_not_found}
    end

    test "returns {:error, :invalid_parameter} if attributes are not matched" do
      user = insert(:user)

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
      user = insert(:user)
      assert {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :secret_code)

      updated_user = User.get(user.id)

      assert attrs == %{
               issuer: "OmiseGO",
               label: updated_user.email,
               secret_2fa_code: updated_user.secret_2fa_code
             }
    end

    test "returns {:ok, backup_codes_attrs} when given :backup_codes" do
      user = insert(:user)
      assert {:ok, attrs} = TwoFactorAuthenticator.create_and_update(user, :backup_codes)

      updated_user = User.get(user.id)

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
    test "returns an auth token when enabled 2fa" do
      user = insert(:user)

      assert {:ok, auth_token} = TwoFactorAuthenticator.enable(user, nil, :admin_api, true)
      assert auth_token.token != nil
      assert auth_token.pre_token == nil
    end

    test "the user's `enabled_2fa_at` should not be nil when enabled 2fa" do
      user = insert(:user)

      assert {:ok, _} = TwoFactorAuthenticator.enable(user, nil, :admin_api, true)

      updated_user = User.get(user.id)

      assert updated_user.enabled_2fa_at != nil
    end

    test "the user's `enabled_2fa_at` should be nil when disabled 2fa" do
      user = insert(:user)
      auth_token = AuthToken.generate_token(user, :admin_api, user)

      assert {:ok, _} = TwoFactorAuthenticator.enable(user, auth_token, :admin_api, false)

      updated_user = User.get(user.id)

      assert updated_user.enabled_2fa_at == nil
    end
  end

  defp generate_totp(secret_code), do: :pot.totp(secret_code)
end
