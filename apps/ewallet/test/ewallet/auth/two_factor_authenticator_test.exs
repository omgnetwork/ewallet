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

  describe "login" do
    test "returns {:ok, auth_token} if the user has secret code and the given passcode is correct" do
      user = insert(:user)

      {_, secret_2fa_code, enabled_2fa_user} = create_two_factors_and_enable_2fa(user)

      passcode = generate_totp(secret_2fa_code)

      params = %{"passcode" => passcode}

      assert {:ok, auth_token} =
               TwoFactorAuthenticator.login(params, :admin_api, enabled_2fa_user)

      assert auth_token.token != nil
    end

    test "returns {:ok, auth_token} if the user has hashed backup codes and the given backup code is correct" do
      user = insert(:user)

      {[backup_code | _], _, enabled_2fa_user} = create_two_factors_and_enable_2fa(user)

      params = %{"backup_code" => backup_code}

      assert {:ok, auth_token} =
               TwoFactorAuthenticator.login(params, :admin_api, enabled_2fa_user)

      assert auth_token.token != nil
    end

    test "returns {:error, :user_2fa_disabled} if the user has not enabled two-factor authorization" do
      user = insert(:user)

      TwoFactorAuthenticator.create_and_update(user, :backup_codes, %{number_of_backup_codes: 1})

      updated_user = User.get(user.id)

      assert TwoFactorAuthenticator.login(%{"secret_code" => "123456"}, :admin_api, updated_user) ==
               {:error, :user_2fa_disabled}
    end
  end

  describe "verify" do
    test "returns {:ok} if the user has secret code and the given passcode is correct" do
      user = insert(:user)

      {attrs, created_secret_code_user} = create_secret_code(user)

      passcode = generate_totp(attrs.secret_2fa_code)

      assert TwoFactorAuthenticator.verify(%{"passcode" => passcode}, created_secret_code_user) ==
               {:ok}
    end

    test "returns {:ok} if the user has hashed backup codes and the given backup code is correct" do
      user = insert(:user)

      {attrs, updated_user} = create_backup_codes(user)

      assert TwoFactorAuthenticator.verify(
               %{"backup_code" => hd(attrs.backup_codes)},
               updated_user
             ) == {:ok}
    end

    test "returns {:error, :invalid_passcode} if the user has secret code but the given passcode is incorrect" do
      user = insert(:user)

      {_, updated_user} = create_secret_code(user)

      assert TwoFactorAuthenticator.verify(%{"passcode" => "nil"}, updated_user) ==
               {:error, :invalid_passcode}
    end

    test "returns {:error, :invalid_backup_code} if the user has backup_codes but the given backup_code is incorrect" do
      user = insert(:user)

      {_, updated_user} = create_backup_codes(user)

      assert TwoFactorAuthenticator.verify(%{"backup_code" => "nil"}, updated_user) ==
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

      {_, updated_user} = create_backup_codes(user)

      assert TwoFactorAuthenticator.verify(%{"sms_otp" => "¬_¬"}, updated_user) ==
               {:error, :invalid_parameter,
                "Invalid parameter provided. `backup_code` or `passcode` is required."}
    end

    test "returns {:error, :invalid_parameter} if the user is nil" do
      assert TwoFactorAuthenticator.verify(%{"passcode" => "¯\_(ツ)_/¯"}, nil) ==
               {:error, :invalid_parameter}
    end
  end

  describe "verify_multiple" do
    test "returns {:error, :invalid_parameter} when the attributes are empty" do
      user = insert(:user)

      assert TwoFactorAuthenticator.verify_multiple(%{}, user) == {:error, :invalid_parameter}
    end

    test "returns {:error, :invalid_backup_code} when the invalid backup_code is passed" do
      user = insert(:user)

      {_, updated_user} = create_backup_codes(user)

      assert TwoFactorAuthenticator.verify_multiple(
               %{"backup_code" => "12345678"},
               updated_user
             ) == {:error, :invalid_backup_code}
    end

    test "returns {:error, :invalid_passcode} when the invalid passcode is passed" do
      user = insert(:user)

      {_, updated_user} = create_secret_code(user)

      assert TwoFactorAuthenticator.verify_multiple(%{"passcode" => "123456"}, updated_user) ==
               {:error, :invalid_passcode}
    end

    test "returns {:error, :passcode_not_found} when the secret_2fa_code has not been created" do
      user = insert(:user)

      assert TwoFactorAuthenticator.verify_multiple(%{"passcode" => "123456"}, user) ==
               {:error, :secret_code_not_found}
    end

    test "returns {:error, :backup_code_not_found} when the hashed_backup_codes has not been created" do
      user = insert(:user)

      assert TwoFactorAuthenticator.verify_multiple(%{"backup_code" => "123456"}, user) ==
               {:error, :backup_codes_not_found}
    end

    test "returns {:ok} when the valid passcode is passed" do
      user = insert(:user)

      {attrs, updated_user} = create_secret_code(user)

      passcode = generate_totp(attrs.secret_2fa_code)

      assert TwoFactorAuthenticator.verify_multiple(%{"passcode" => passcode}, updated_user) ==
               {:ok}
    end

    test "returns {:ok} when the valid backup_code is passed" do
      user = insert(:user)

      {attrs, updated_user} = create_backup_codes(user)

      assert TwoFactorAuthenticator.verify_multiple(
               %{"backup_code" => hd(attrs.backup_codes)},
               updated_user
             ) == {:ok}
    end

    test "returns {:ok} when both valid passcode and backup_code are passed" do
      user = insert(:user)

      {backup_code_attrs, updated_user} = create_backup_codes(user)
      {secret_code_attrs, updated_user} = create_secret_code(updated_user)

      passcode = generate_totp(secret_code_attrs.secret_2fa_code)

      assert TwoFactorAuthenticator.verify_multiple(
               %{
                 "backup_code" => hd(backup_code_attrs.backup_codes),
                 "passcode" => passcode
               },
               updated_user
             ) == {:ok}
    end

    test "returns {:error, :invalid_backup_code} when the valid passcode and the invalid backup_code are passed" do
      user = insert(:user)

      {_, updated_user} = create_backup_codes(user)
      {secret_code_attrs, updated_user} = create_secret_code(updated_user)

      passcode = generate_totp(secret_code_attrs.secret_2fa_code)

      assert TwoFactorAuthenticator.verify_multiple(
               %{
                 "backup_code" => "12345",
                 "passcode" => passcode
               },
               updated_user
             ) == {:error, :invalid_backup_code}
    end

    test "returns {:error, :invalid_passcode} when the invalid passcode and the valid backup_code are passed" do
      user = insert(:user)

      {backup_code_attrs, updated_user} = create_backup_codes(user)

      {_, updated_user} = create_secret_code(updated_user)

      assert TwoFactorAuthenticator.verify_multiple(
               %{
                 "backup_code" => hd(backup_code_attrs.backup_codes),
                 "passcode" => "123456"
               },
               updated_user
             ) == {:error, :invalid_passcode}
    end
  end

  describe "create_and_update" do
    test "returns {:ok, secret_code_attrs} when given :secret_code" do
      user = insert(:user)

      {attrs, updated_user} = create_secret_code(user)

      assert attrs == %{
               issuer: "OmiseGO",
               label: updated_user.email,
               secret_2fa_code: updated_user.secret_2fa_code
             }
    end

    test "returns {:ok, backup_codes_attrs} when given :backup_codes" do
      user = insert(:user)

      {attrs, updated_user} = create_backup_codes(user)

      assert length(attrs.backup_codes) == 10

      assert Enum.all?(
               attrs.backup_codes,
               &verify_backup_code(&1, updated_user.hashed_backup_codes)
             )
    end

    test "returns {:error, :invalid_parameter} when given unsupported 2fa method" do
      user = insert(:user)

      assert TwoFactorAuthenticator.create_and_update(user, :something) ==
               {:error, :invalid_parameter}
    end

    defp verify_backup_code(backup_code, hashed_backup_codes) do
      Enum.any?(hashed_backup_codes, fn hashed_backup_code ->
        Crypto.verify_password(backup_code, hashed_backup_code)
      end)
    end
  end

  describe "enable" do
    test "returns {:ok, auth_token} when enabled 2fa" do
      user = insert(:user)

      create_backup_codes(user)
      {_, updated_user} = create_secret_code(user)

      # Assert auth token
      assert {:ok} = TwoFactorAuthenticator.enable(updated_user, :admin_api)

      # Assert updated user
      updated_user = User.get(user.id)
      assert updated_user.enabled_2fa_at != nil
      assert updated_user.hashed_backup_codes != []
      assert updated_user.secret_2fa_code != nil
    end

    test "returns {:error, :backup_codes_not_found} when backup_code has not been created" do
      user = insert(:user)

      {_, updated_user} = create_secret_code(user)

      assert {:error, :backup_codes_not_found} =
               TwoFactorAuthenticator.enable(updated_user, :admin_api)
    end

    test "returns {:error, :secret_code_not_found} when secret_2fa_code has not been created" do
      user = insert(:user)

      {_, updated_user} = create_backup_codes(user)

      assert {:error, :secret_code_not_found} =
               TwoFactorAuthenticator.enable(updated_user, :admin_api)
    end
  end

  describe "disable" do
    test "returns an auth token when disable 2fa" do
      user = insert(:user)
      auth_token = insert(:auth_token, user: user, owner_app: "admin_api")

      assert {:ok} = TwoFactorAuthenticator.disable(user, :admin_api)

      assert auth_token.token != nil
    end

    test "the user's two-factor related properties should be unset" do
      user = insert(:user)
      {:ok, _} = AuthToken.generate(user, :admin_api, user)

      assert {:ok} = TwoFactorAuthenticator.disable(user, :admin_api)

      updated_user = User.get(user.id)

      assert updated_user.enabled_2fa_at == nil
      assert updated_user.hashed_backup_codes == []
      assert updated_user.secret_2fa_code == nil
    end
  end

  defp create_two_factors_and_enable_2fa(user) do
    {secret_code_attrs, _} = create_secret_code(user)
    {backup_code_attrs, created_backup_codes_user} = create_backup_codes(user)

    TwoFactorAuthenticator.enable(created_backup_codes_user, :admin_api)

    {backup_code_attrs.backup_codes, secret_code_attrs.secret_2fa_code, User.get(user.id)}
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
