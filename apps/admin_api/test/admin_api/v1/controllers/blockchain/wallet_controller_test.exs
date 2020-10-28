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

defmodule AdminAPI.V1.Blockchain.WalletControllerTest do
  use AdminAPI.ConnCase, async: false

  describe "/wallet.create" do
    test_with_auths "fails to insert a wallet when internal_enabled is false", context do
      enable_blockchain(context)

      account = insert(:account)

      response =
        request("/wallet.create", %{
          name: "MyWallet",
          identifier: "secondary",
          account_id: account.id
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "wallet:internal_wallets_disabled",
               "description" => "Internal wallets cannot be created.",
               "messages" => nil,
               "object" => "error"
             }
    end
  end
end
