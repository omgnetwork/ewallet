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

defmodule EWallet.Bouncer.MintTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{MintTarget, DispatchConfig}

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the mint" do
      account = insert(:account)
      token = insert(:token, account: account)
      mint = insert(:mint, token_uuid: token.uuid)
      res = MintTarget.get_owner_uuids(mint)
      assert res == [account.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert MintTarget.get_target_types() == [:mints]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given mint" do
      assert MintTarget.get_target_type(Mint) == :mints
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the mint" do
      account = insert(:account)
      token = insert(:token, account: account)
      mint = insert(:mint, token_uuid: token.uuid)

      target_accounts_uuids =
        mint |> MintTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end
  end
end
