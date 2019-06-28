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

defmodule EWallet.BackupCodeAuthenticator do
  alias Utils.Helpers.Crypto
  alias EWalletDB.UserBackupCode

  @moduledoc """
  Handle verify backup_code with hashed_backup_codes and create new backup codes.

  Example:

  # Create backup codes.
  iex(4)> EWallet.BackupCodeAuthenticator.create(3)
  {
    :ok,
    [
      "7c501e31",
      "ecd704eb",
      "25f5da3f"
    ]
  }

  The response format is {:ok, backup_codes, hashed_backup_codes}

  # Verify backup code with associated hashed_backup_codes.
  iex> EWallet.BackupCodeAuthenticator.verify([
    "c45fe340110ebf6d6e1d88dd4695a1cb97089e291f8a6adf68ca4a9e8a0d620b5bad7937cc752fc1ce95cbc55ab7b053",
    "fd203d599a82e1a0b6e91361c1cfdc4fca0623983eb25da38f0c45dc403051b8c1ffa54321c5de8f59477a687e524a35",
    "06d33264eec2ca3c6a6c07b5f3a0fd87d854a53f739e60ac2da654023d900370506e9218d5f2abad5e19e4e9593009d8"
  ], "7c501e31")

  # Success
  :ok

  # Failure
  {:error, :invalid_backup_code}

  """

  @number_of_bytes 4

  def verify(_, _, nil), do: {:error, :invalid_backup_code}

  def verify(backup_code_created_at, hashed_backup_codes, backup_code)
      when is_list(hashed_backup_codes) and is_binary(backup_code) do
    case Enum.find_index(hashed_backup_codes, &do_verify(backup_code, &1.hashed_backup_code)) do
      nil ->
        {:error, :invalid_backup_code}

      index ->
        hashed_backup_codes
        |> Enum.at(index)
        |> verify_result(backup_code_created_at)
    end
  end

  def verify(_, _, _), do: {:error, :invalid_parameter}

  defp do_verify(backup_code, hashed_backup_code) do
    backup_code
    |> Base.encode64(padding: false)
    |> Crypto.verify_secret(hashed_backup_code)
  end

  defp verify_result(%UserBackupCode{} = user_backup_code, backup_code_created_at) do
    case user_backup_code do
      %{inserted_at: inserted_at, used_at: nil} when inserted_at >= backup_code_created_at ->
        {:ok, user_backup_code}

      _ ->
        {:error, :invalid_backup_code}
    end
  end

  def create(number_of_backup_codes)
      when is_integer(number_of_backup_codes) and number_of_backup_codes > 0 do
    backup_codes =
      1..number_of_backup_codes
      |> Enum.map(fn _ -> do_create() end)

    {:ok, backup_codes}
  end

  def create(_), do: {:error, :invalid_parameter}

  defp do_create do
    @number_of_bytes
    |> Crypto.generate_base16_key()
    |> String.downcase()
  end
end
