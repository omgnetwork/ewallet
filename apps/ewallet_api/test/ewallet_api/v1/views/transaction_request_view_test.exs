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

defmodule EWalletAPI.V1.TransactionRequestViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.{TransactionRequestSerializer, TransactionRequestOverlay}
  alias EWalletAPI.V1.TransactionRequestView
  alias EWalletDB.TransactionRequest

  describe "EWalletAPI.V1.TransactionRequestView.render/2" do
    test "renders transaction_request.json with correct structure" do
      request = insert(:transaction_request)

      transaction_request =
        TransactionRequest.get(
          request.id,
          preload: TransactionRequestOverlay.default_preload_assocs()
        )

      expected = %{
        version: @expected_version,
        success: true,
        data: TransactionRequestSerializer.serialize(transaction_request)
      }

      assert render(
               TransactionRequestView,
               "transaction_request.json",
               transaction_request: transaction_request
             ) == expected
    end
  end
end
