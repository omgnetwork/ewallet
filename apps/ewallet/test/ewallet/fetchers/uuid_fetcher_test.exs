# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.UUIDFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.UUIDFetcher
  alias EWalletDB.{Account, User}

  describe "replace_external_ids/1" do
    test "turns multiple external IDs into internal UUIDs" do
      user = insert(:user)
      account = insert(:account)

      attrs = %{
        "user_id" => user.id,
        "account_id" => account.id
      }

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == account.uuid
      assert %Account{} = res["account"]
      assert res["user_uuid"] == user.uuid
      assert %User{} = res["user"]
    end

    test "turns provider_user_id into user_uuid" do
      user = insert(:user)
      attrs = %{"provider_user_id" => user.provider_user_id}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["user_uuid"] == user.uuid
      assert %User{} = res["user"]
    end

    test "turns external IDs into internal UUIDs" do
      account = insert(:account)
      attrs = %{"account_id" => account.id}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == account.uuid
      assert %Account{} = res["account"]
    end

    test "turns external IDs into internal UUIDs if the record does not exist" do
      attrs = %{"account_id" => "some_id"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res["account_uuid"] == nil
      assert res["account"] == nil
    end

    test "returns the same attributes if no external IDs is given" do
      attrs = %{"something" => "else"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res == %{"something" => "else"}
    end

    test "returns the same attributes if external IDs are not supported" do
      attrs = %{"something_id" => "fake_id"}

      res = UUIDFetcher.replace_external_ids(attrs)
      assert res == %{"something_id" => "fake_id"}
    end
  end
end
