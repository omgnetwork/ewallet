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
  alias EWalletDB.{User, AuthToken, PreAuthToken}

  @moduledoc """
  Handle of login, create, enable and disable 2FA logic.
  The two-factor authentication methods can be different, this module will form particular parameters,
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

  @default_number_of_backup_codes 10
  @default_issuer "OmiseGO"

  def login(_, _, %User{enabled_2fa_at: nil}), do: {:error, :user_2fa_disabled}

  def login(attrs, owner_app, %User{} = user) do
    with :ok <- verify(attrs, user),
         :ok <- PreAuthToken.delete_for_user(user) do
      AuthToken.generate(user, owner_app, user)
    else
      error -> error
    end
  end

  # Verify multiple two-factor authentication factors.
  # Example:
  # iex> TwoFactorAuthenticator.verify_multiple(
  #  %{"secret_code" => "123456", "backup_codes" => "12345678"},
  #  user
  # )
  #
  # :ok
  def verify_multiple(attrs, user) when map_size(attrs) > 0 do
    with sub_attrs <- Enum.map(attrs, fn {k, v} -> Map.put(%{}, k, v) end),
         sub_results <- Enum.map(sub_attrs, &verify(&1, user)),
         [] <- Enum.filter(sub_results, &match?({:error, _}, &1)) do
      :ok
    else
      errors ->
        hd(errors)
    end
  end

  def verify_multiple(_, _), do: {:error, :invalid_parameter}

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
         "user" => %User{hashed_backup_codes: hashed_backup_codes} = user
       })
       when is_binary(backup_code) do
    case BackupCodeAuthenticator.verify(hashed_backup_codes, backup_code) do
      {:ok, updated_backup_codes} ->
        User.set_hashed_backup_codes(user, %{
          "hashed_backup_codes" => updated_backup_codes,
          "originator" => user
        })

        :ok

      error ->
        error
    end
  end

  defp do_verify(%{"user" => _}) do
    error_description = "Invalid parameter provided. `backup_code` or `passcode` is required."
    {:error, :invalid_parameter, error_description}
  end

  defp do_verify(_) do
    {:error, :invalid_parameter}
  end

  def create_and_update(%User{} = user, :secret_code) do
    {:ok, secret_code} = PasscodeAuthenticator.create()

    User.set_secret_code(user, %{
      "secret_2fa_code" => secret_code,
      "originator" => user
    })

    {:ok, %{secret_2fa_code: secret_code, issuer: get_issuer(), label: user.email}}
  end

  def create_and_update(%User{} = user, :backup_codes) do
    {:ok, backup_codes, hashed_backup_codes} =
      get_number_of_backup_codes()
      |> BackupCodeAuthenticator.create()

    User.set_hashed_backup_codes(user, %{
      "hashed_backup_codes" => hashed_backup_codes,
      "originator" => user
    })

    {:ok, %{backup_codes: backup_codes}}
  end

  def create_and_update(_, _) do
    {:error, :invalid_parameter}
  end

  defp get_issuer do
    Application.get_env(:ewallet, :issuer, @default_issuer)
  end

  defp get_number_of_backup_codes do
    case Application.get_env(:ewallet, :number_of_backup_codes, @default_number_of_backup_codes) do
      number_of_backup_codes
      when is_integer(number_of_backup_codes) and number_of_backup_codes > 1 ->
        number_of_backup_codes

      _ ->
        @default_number_of_backup_codes
    end
  end

  # Enable two-factor authentication for specified user.
  # All tokens belong to this user will be deleted.
  # The client will then need to do 2-steps login to obtain the authentication_token.
  #
  # Note: The responsibility of two-factor params verification will be left here.
  # However, it does a small check that the user has already created some two-factor methods.
  def enable(%User{} = user) do
    with :ok <- validate_enable_attrs(user),
         {:ok, updated_user} <- User.enable_2fa(user),
         :ok <- AuthToken.delete_for_user(updated_user) do
      :ok
    else
      error -> error
    end
  end

  defp validate_enable_attrs(user) do
    cond do
      Enum.empty?(user.hashed_backup_codes) ->
        {:error, :backup_codes_not_found}

      is_nil(user.secret_2fa_code) ->
        {:error, :secret_code_not_found}

      true ->
        :ok
    end
  end

  # Disable two-factor authentication for specified user.
  # All tokens, hashed_backup_codes and secret_2fa_code belong to this user will be deleted.
  # The client will then need to re-login to obtain the authentication_token.
  #
  # Note: The responsibility of two-factor params verification will be left here.
  # However, it does a small check that the user has already created some two-factor methods.
  def disable(%User{} = user) do
    with {:ok, updated_user} <- User.disable_2fa(user),
         AuthToken.delete_for_user(updated_user) do
      :ok
    else
      error -> error
    end
  end
end
