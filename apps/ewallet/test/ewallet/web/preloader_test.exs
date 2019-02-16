# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.PreloaderTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Web.Preloader
  alias EWalletDB.{Repo, Token, Transaction}

  defp prepare_test_transactions do
    insert(:transaction)
    insert(:transaction)
  end

  describe "EWallet.Web.Preloader.to_query/2" do
    test "preloads the from_token association" do
      prepare_test_transactions()

      result =
        Transaction
        |> Preloader.to_query([:from_token])
        |> Repo.all()

      assert Enum.count(result) == 2
      assert %Token{} = Enum.at(result, 0).from_token
    end
  end
end
