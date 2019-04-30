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
    ],
    [
      "$2b$12$a9m6U7NG2C.5R1LluPBDBO9dscWhZEO7XyNDaMaNG3bff5vwiHxRK",
      "$2b$12$58HR6Tc/hbH77JH6/RS3wusR4.NI/eP26mAuC2K6/.f.zLPomo4uK",
      "$2b$12$xwrHaJb9YvYDFVusSxohvexH36IW6p/mlICobmR7muzAxnrmBiP.6"
    ]
  }

  The response format is {:ok, backup_codes, hashed_backup_codes}

  # Verify backup code with associated hashed_backup_codes.
  iex> EWallet.BackupCodeAuthenticator.verify([
    "$2b$12$a9m6U7NG2C.5R1LluPBDBO9dscWhZEO7XyNDaMaNG3bff5vwiHxRK",
    "$2b$12$58HR6Tc/hbH77JH6/RS3wusR4.NI/eP26mAuC2K6/.f.zLPomo4uK",
    "$2b$12$xwrHaJb9YvYDFVusSxohvexH36IW6p/mlICobmR7muzAxnrmBiP.6"
  ], "7c501e31")

  # Success
  :ok

  # Failure
  {:error, :invalid_backup_code}

  """

  @number_of_bytes 4

  def verify(_, nil), do: {:error, :invalid_backup_code}

  def verify(hashed_backup_codes, backup_code)
      when is_list(hashed_backup_codes) and is_binary(backup_code) do
    case Enum.find_index(hashed_backup_codes, &Crypto.verify_password(backup_code, &1)) do
      nil ->
        {:error, :invalid_backup_code}

      index ->
        {:ok, List.delete_at(hashed_backup_codes, index)}
    end
  end

  def verify(_, _), do: {:error, :invalid_parameter}

  def create(number_of_backup_codes)
      when is_integer(number_of_backup_codes) and number_of_backup_codes > 0 do
    backup_codes =
      1..number_of_backup_codes
      |> Enum.map(fn _ -> do_create() end)

    hashed_backup_codes =
      backup_codes
      |> Enum.map(&Task.async(fn -> Crypto.hash_password(&1) end))
      |> Enum.map(&Task.await(&1))

    {:ok, backup_codes, hashed_backup_codes}
  end

  def create(_), do: {:error, :invalid_parameter}

  defp do_create do
    @number_of_bytes
    |> Crypto.generate_base16_key()
    |> String.downcase()
  end
end
