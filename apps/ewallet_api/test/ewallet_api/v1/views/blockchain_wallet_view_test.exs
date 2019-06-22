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

defmodule EWalletAPI.V1.BlockchainWalletViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.BlockchainWalletView
  alias EWallet.BlockchainBalanceFetcher
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.BlockchainWalletSerializer
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedgerDB.Repo, as: LocalLedgerDBRepo

  describe "render/2" do
    # TODO: Need to be updated
    test "renders wallets.json with the given wallets" do
      blockchain_wallet_1 = insert(:blockchain_wallet)
      blockchain_wallet_2 = insert(:blockchain_wallet)

      token_1 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000000"})

      token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      {:ok, blockchain_wallets_with_balances} =
        BlockchainBalanceFetcher.all([blockchain_wallet_1, blockchain_wallet_2], [token_1, token_2])

      paginator = %Paginator{
        data: blockchain_wallets_with_balances,
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      IO.inspect(paginator)

      expected = %{
        version: @expected_version,
        success: true,
        data: BlockchainWalletSerializer.serialize(paginator)
      }

      assert BlockchainWalletView.render("wallets.json", %{wallets: paginator}) == expected
    end
  end
end
