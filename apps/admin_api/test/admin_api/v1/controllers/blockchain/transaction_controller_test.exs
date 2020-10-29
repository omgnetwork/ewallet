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

defmodule AdminAPI.V1.Blockchain.TransactionControllerTest do
  use AdminAPI.ConnCase, async: false

  describe "/transaction.create for same-token transactions" do
    test_with_auths "returns an error when internal_enabled is false", context do
      enable_blockchain(context)

      response =
        request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => "abc",
          "to_address" => "def",
          "token_id" => 123,
          "amount" => 1_000_000
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:internal_transactions_disabled"

      assert response["data"]["description"] ==
               "Internal transactions cannot be created."
    end
  end
end
