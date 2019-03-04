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

defmodule AdminAPI.V1.BalanceControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWallet.Web.V1.UserSerializer
  alias EWalletDB.{Account, AccountUser, Repo, Token, User, Wallet}
  alias ActivityLogger.System

  describe "/wallet.all_balances" do
    test_with_auths "returns a list of balances and pagination data" do
      account = Account.get_master_account()
      master_wallet = Account.get_primary_wallet(account)

      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)

      {:ok, btc} = :token |> params_for() |> Token.insert()
      {:ok, omg} = :token |> params_for() |> Token.insert()

      mint!(btc)
      mint!(omg)

      transfer!(master_wallet.address, user_wallet.address, btc, 150_000 * btc.subunit_to_unit)
      transfer!(master_wallet.address, user_wallet.address, omg, 12_000 * omg.subunit_to_unit)

      attrs = %{
        "sort_by" => "id",
        "sort_dir" => "desc",
        "per_page" => 1,
        "start_after" => nil,
        "address" => user_wallet.address
      }

      response = request("/wallet.all_balances", attrs)

      assert response["success"] == true
      assert response["data"]["pagination"]["count"] == 1
      assert [%{"amount" => 1_200_000}] = response["data"]["data"]
    end
  end
end
