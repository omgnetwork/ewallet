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

defmodule EWalletDB.UserBackupCodeTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{UserBackupCode}

  describe "insert/1" do
    test "returns :ok when given hashed_backup_codes and user_uuid" do
      user = insert(:user)
      hashed_backup_codes = ["1234", "5678"]

      assert {:ok, user_backup_codes} =
               UserBackupCode.insert_multiple(%{
                 hashed_backup_codes: hashed_backup_codes,
                 user_uuid: user.uuid
               })

      # Verify all inserted hashed_backup_codes are matched with the given hashed_backup_codes
      assert Enum.map(user_backup_codes, fn {_, user_backup_code} ->
               user_backup_code.hashed_backup_code
             end) == hashed_backup_codes

      # Verify all user_backup_codes are belong to given user.
      # Verify all user_backup_codes.used_at are nil
      assert Enum.all?(user_backup_codes, fn {_, user_backup_code} ->
               user_backup_code.user_uuid == user.uuid and user_backup_code.used_at == nil
             end)
    end

    test "returns {:error, :invalid_parameter} when the user_uuid is nil or missing" do
      attrs = %{
        hashed_backup_codes: ["1234"],
        user_uuid: nil
      }

      assert UserBackupCode.insert_multiple(attrs) == {:error, :invalid_parameter}
    end
  end

  describe "all_for_user/1" do
    test "returns all user_backup_codes belong to the user when given a valid uuid" do
      %{uuid: user_uuid} = insert(:user)

      hashed_backup_codes = ["1234", "5678"]

      UserBackupCode.insert_multiple(%{
        hashed_backup_codes: hashed_backup_codes,
        user_uuid: user_uuid
      })

      assert [
               %UserBackupCode{
                 hashed_backup_code: "1234",
                 used_at: nil,
                 user_uuid: user_uuid
               },
               %UserBackupCode{
                 hashed_backup_code: "5678",
                 used_at: nil,
                 user_uuid: user_uuid
               }
             ] = UserBackupCode.all_for_user(user_uuid)
    end

    test "return empty list when the user_backup_codes are not found for given user" do
      user = insert(:user)
      assert UserBackupCode.all_for_user(user.uuid) == []
    end
  end

  describe "delete_for_user/1" do
    test "returns :ok when delete all user_backup_codes belong to the given user_uuid" do
      user = insert(:user)
      hashed_backup_codes = ["1234", "5678"]

      UserBackupCode.insert_multiple(%{
        hashed_backup_codes: hashed_backup_codes,
        user_uuid: user.uuid
      })

      assert UserBackupCode.delete_for_user(user.uuid) == :ok
      assert UserBackupCode.all_for_user(user.uuid) == []
    end
  end

  describe "invalidate/1" do
    test "return {:ok, updated_user_backup_code} and set given user_backup_code.used_at to now when specify a valid user_backup_code" do
      user = insert(:user)
      hashed_backup_codes = ["1234", "5678"]

      {:ok, attrs} =
        UserBackupCode.insert_multiple(%{
          hashed_backup_codes: hashed_backup_codes,
          user_uuid: user.uuid
        })

      assert {:ok, updated_user_backup_code} = UserBackupCode.invalidate(attrs.ubc_0)
      assert updated_user_backup_code.hashed_backup_code == "1234"
      assert updated_user_backup_code.used_at != nil
    end
  end
end
