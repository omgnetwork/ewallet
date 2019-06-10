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

defmodule EWallet.BlockchainBalanceFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.BlockchainBalanceFetcher

  describe "all/2" do
    test "returns a list of balances of given tokens when given wallet address and non-empty tokens" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      token_1 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000000"})

      token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      assert {:ok, balances} =
               BlockchainBalanceFetcher.all(blockchain_wallet.address, [token_1, token_2])

      assert [balance_token_1, balance_token_2] = balances

      assert balance_token_1 == %{token: token_1, amount: 123}
      assert balance_token_2 == %{token: token_2, amount: 123}
    end

    test "returns an empty list when given wallet and empty tokens" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      assert {:ok, balances} = BlockchainBalanceFetcher.all(blockchain_wallet.address, [])

      assert balances == []
    end
  end
end
