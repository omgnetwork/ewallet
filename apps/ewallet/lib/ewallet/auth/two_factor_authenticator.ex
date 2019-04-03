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

alias EWallet.PasscodeAuthenticator
alias EWallet.BackupCodeAuthenticator
alias EWalletDB.{User, AuthToken}

defmodule EWallet.TwoFactorAuthenticator do
  @moduledoc """
  Handle of verify, create, enable and disable 2FA logic.
  The authentication methods can be different, this module will form particular parameters,
  then delegate call to the particular module e.g. `BackupCodeAuthenticator` or `PasscodeAuthenticator`.

  Note that some operations like create, enable and disable will updating the corresponding entity as well:
  - create_and_update:
    - Update encrypted_backup_codes or secret_2fa_code for user entity.
  - enable:
    - Update `required_2fa` to `true` for all auth tokens belong to this user. (all tokens cannot be used anymore.)
    - Update `enabled_2fa_at` to the current naive date time for user entity.
    - Generate new auth_token with `required_2fa` `false`. (this token is 2FA authenticated. Use this token instead.)
  - disable:
    - Clear `enabled_2fa_at`, `encrypted_backup_codes`, `secret_2fa_code` for user entity.
    - Update `required_2fa` to `false` for the current auth token. (this token can still be used)
  """

  @number_of_backup_codes 10

  def verify(attrs, %User{} = user) do
    attrs
    |> Map.put("user", user)
    |> do_verify()
  end

  def verify(_, _) do
    {:error, :invalid_parameter}
  end

  defp do_verify(%{"passcode" => _, "user" => %User{secret_2fa_code: nil}}) do
    {:error, :secret_code_not_found}
  end

  defp do_verify(%{"backup_code" => _, "user" => %User{encrypted_backup_codes: []}}) do
    {:error, :backup_codes_not_found}
  end

  defp do_verify(%{"passcode" => passcode, "user" => %User{secret_2fa_code: secret_2fa_code}})
       when is_binary(passcode) do
    PasscodeAuthenticator.verify(passcode, secret_2fa_code)
  end

  defp do_verify(%{
         "backup_code" => backup_code,
         "user" => %User{encrypted_backup_codes: encrypted_backup_codes}
       })
       when is_binary(backup_code) do
    BackupCodeAuthenticator.verify(encrypted_backup_codes, backup_code)
  end

  def create_and_update(user, type, ops \\ %{number_of_backup_codes: @number_of_backup_codes})

  def create_and_update(%User{} = user, :secret_code, _) do
    {:ok, secret_code} = PasscodeAuthenticator.create()

    User.set_secret_code(user, %{
      "secret_2fa_code" => secret_code,
      "originator" => user
    })
  end

  def create_and_update(
        %User{} = user,
        :backup_codes,
        %{number_of_backup_codes: number_of_backup_codes}
      )
      when number_of_backup_codes > 0 do
    {:ok, backup_codes, encrypted_backup_codes} =
      BackupCodeAuthenticator.create(number_of_backup_codes)

    User.set_encrypted_backup_codes(user, %{
      "encrypted_backup_codes" => encrypted_backup_codes,
      "originator" => user
    })

    {:ok, %{backup_codes: backup_codes}}
  end

  def create_and_update(_, _, _) do
    {:error, :invalid_parameters}
  end

  # Enable 2FA
  def enable(%User{} = user, _, owner_app, true) do
    AuthToken.set_required_2fa_for_user(user, true)

    {:ok, updated_user} =
      User.set_enabled_2fa_at(
        user,
        %{
          "enabled_2fa_at" => NaiveDateTime.utc_now(),
          "originator" => user
        }
      )

    AuthToken.generate(updated_user, owner_app, updated_user, true)
  end

  # Disable 2FA
  def enable(%User{} = user, token_string, owner_app, false) do
    with {:ok, updated_user} <-
           User.set_secret_code(user, %{
             "secret_2fa_code" => nil,
             "originator" => user
           }),
         {:ok, updated_user} <-
           User.set_encrypted_backup_codes(user, %{
             "encrypted_backup_codes" => [],
             "originator" => updated_user
           }),
         {:ok, updated_user} <-
           User.set_enabled_2fa_at(user, %{
             "enabled_2fa_at" => nil,
             "originator" => updated_user
           }),
         :ok = AuthToken.set_required_2fa_for_user(updated_user, false) do
      {:ok, AuthToken.get_by_token(token_string, owner_app)}
    else
      error -> error
    end
  end
end
