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

alias Utils.Helpers.Crypto

defmodule EWallet.BackupCodeAuthenticator do
  @number_of_bytes 4

  def verify(encrypted_backup_codes, backup_code) do
    if Enum.any?(encrypted_backup_codes, &Crypto.verify_password(backup_code, &1)) do
      {:ok}
    else
      {:error, :invalid_backup_code}
    end
  end

  def create(number_of_backup_codes) do
    backup_codes =
      1..number_of_backup_codes
      |> Enum.map(fn _ -> do_create() end)

    encrypted_backup_codes =
      backup_codes
      |> Enum.map(&Task.async(fn -> Crypto.hash_password(&1) end))
      |> Enum.map(&Task.await(&1))

    {:ok, backup_codes, encrypted_backup_codes}
  end

  defp do_create() do
    @number_of_bytes
    |> Crypto.generate_base16_key()
    |> String.downcase()
  end
end
