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

defmodule EWallet.TwoFactorAuthenticator do
  alias EWallet.PasscodeAuthenticator
  alias EWallet.BackupCodeAuthenticator
  alias EWalletDB.{User, AuthToken}

  @moduledoc """
  Handle of verify, create, enable and disable 2FA logic.
  The authentication methods can be different, this module will form particular parameters,
  then delegate call to the particular module e.g. `BackupCodeAuthenticator` or `PasscodeAuthenticator`.

  Note that some operations like create, enable and disable will updating the corresponding entity as well:
  - create_and_update:
    - Update hashed_backup_codes or secret_2fa_code for user entity.
  - enable:
    - Remove all auth tokens belong to this user. (all existed tokens cannot be used anymore.)
    - Update `enabled_2fa_at` to the current naive date time for user entity.
    - Create a new auth_token. (The client must upgrade to this token)
  - disable:
    - Clear `enabled_2fa_at`, `hashed_backup_codes`, `secret_2fa_code` for user entity.
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

  defp do_verify(%{"backup_code" => _, "user" => %User{hashed_backup_codes: []}}) do
    {:error, :backup_codes_not_found}
  end

  defp do_verify(%{"passcode" => passcode, "user" => %User{secret_2fa_code: secret_2fa_code}})
       when is_binary(passcode) do
    PasscodeAuthenticator.verify(passcode, secret_2fa_code)
  end

  defp do_verify(%{
         "backup_code" => backup_code,
         "user" => %User{hashed_backup_codes: hashed_backup_codes}
       })
       when is_binary(backup_code) do
    BackupCodeAuthenticator.verify(hashed_backup_codes, backup_code)
  end

  defp do_verify(_) do
    {:error, :invalid_parameter}
  end

  def create_and_update(user, type, ops \\ %{number_of_backup_codes: @number_of_backup_codes})

  def create_and_update(%User{} = user, :secret_code, _) do
    {:ok, secret_code} = PasscodeAuthenticator.create()

    User.set_secret_code(user, %{
      "secret_2fa_code" => secret_code,
      "originator" => user
    })

    {:ok, %{secret_2fa_code: secret_code, issuer: "OmiseGO", label: user.email}}
  end

  def create_and_update(
        %User{} = user,
        :backup_codes,
        %{number_of_backup_codes: number_of_backup_codes}
      )
      when number_of_backup_codes > 0 do
    {:ok, backup_codes, hashed_backup_codes} =
      BackupCodeAuthenticator.create(number_of_backup_codes)

    User.set_hashed_backup_codes(user, %{
      "hashed_backup_codes" => hashed_backup_codes,
      "originator" => user
    })

    {:ok, %{backup_codes: backup_codes}}
  end

  def create_and_update(_, _, _) do
    {:error, :invalid_parameters}
  end

  # Enable 2FA
  def enable(%User{} = user, _, owner_app, true) do
    with {:ok, updated_user} = User.enable_2fa(user),
         :ok <- AuthToken.delete_for_user(user) do
      AuthToken.generate_token(updated_user, owner_app, updated_user)
    else
      error -> error
    end
  end

  # Disable 2FA
  def enable(%User{} = user, token_string, owner_app, false) do
    with {:ok, updated_user} <- User.disable_2fa(user) do
      {:ok, AuthToken.get_by_token(token_string, owner_app)}
    else
      error -> error
    end
  end
end
