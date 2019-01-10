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

defmodule EWalletAPI.V1.WalletViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.WalletView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.WalletSerializer
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedgerDB.Repo, as: LocalLedgerDBRepo

  setup do
    :ok = Sandbox.checkout(LocalLedgerDBRepo)
  end

  describe "render/2" do
    test "renders wallets.json with the given wallets" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      paginator = %Paginator{
        data: [wallet_1, wallet_2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: WalletSerializer.serialize(paginator)
      }

      assert WalletView.render("wallets.json", %{wallets: paginator}) == expected
    end
  end
end
