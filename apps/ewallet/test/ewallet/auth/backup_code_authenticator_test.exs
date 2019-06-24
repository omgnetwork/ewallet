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

defmodule EWallet.BackupCodeAuthenticatorTest do
  use EWallet.DBCase, async: true
  alias EWallet.BackupCodeAuthenticator
  alias Utils.Helpers.Crypto
  import EWalletDB.Factory
  alias EWalletDB.UserBackupCode

  describe "verify" do
    test "respond :ok when the given backup_code matches with hashed_backup_codes" do
      number_of_backup_codes = 10

      assert {:ok, backup_codes} = BackupCodeAuthenticator.create(number_of_backup_codes)

      hashed_backup_codes = Enum.map(backup_codes, &Crypto.hash_secret/1)

      assert Enum.all?(backup_codes, &BackupCodeAuthenticator.verify(hashed_backup_codes, [], &1))
    end

    test "respond {:error, :invalid_backup_code} when the given backup_code doesn't match with hashed_backup_codes" do
      user_backup_code = insert(:user_backup_code)

      assert BackupCodeAuthenticator.verify(NaiveDateTime.utc_now(), [user_backup_code], "123456") ==
               {:error, :invalid_backup_code}

      assert BackupCodeAuthenticator.verify(NaiveDateTime.utc_now(), [user_backup_code], "") ==
               {:error, :invalid_backup_code}

      assert BackupCodeAuthenticator.verify(NaiveDateTime.utc_now(), [user_backup_code], nil) ==
               {:error, :invalid_backup_code}
    end

    test "respond {:error, :invalid_backup_code} when given the backup_code that is invalid" do
      backup_code = "12345678"
      backup_code_created_date = NaiveDateTime.utc_now()

      user = insert(:user)

      assert {:ok, %{insert_user_backup_code_0: user_backup_code}} =
               UserBackupCode.insert_multiple(%{
                 backup_codes: [backup_code],
                 user_uuid: user.uuid
               })

      assert {:ok, updated_user_backup_code} = UserBackupCode.invalidate(user_backup_code)

      assert BackupCodeAuthenticator.verify(
               backup_code_created_date,
               [updated_user_backup_code],
               backup_code
             ) == {:error, :invalid_backup_code}
    end

    test "respond {:error, :invalid_parameter} when given invalid parameters" do
      assert BackupCodeAuthenticator.verify(nil, "123456", "123456") ==
               {:error, :invalid_parameter}

      assert BackupCodeAuthenticator.verify(nil, "123456", 123) == {:error, :invalid_parameter}
      assert BackupCodeAuthenticator.verify(nil, nil, "123456") == {:error, :invalid_parameter}
    end
  end

  describe "create" do
    test "respond {:ok, backup_codes, hashed_backup_codes}" do
      number_of_backup_codes = 10

      assert {:ok, backup_codes} = BackupCodeAuthenticator.create(number_of_backup_codes)

      assert length(backup_codes) == number_of_backup_codes
    end

    test "respond {:error, :invalid_parameter} when given invalid parameters" do
      assert {:error, :invalid_parameter} = BackupCodeAuthenticator.create(0)
      assert {:error, :invalid_parameter} = BackupCodeAuthenticator.create("0")
    end
  end
end
