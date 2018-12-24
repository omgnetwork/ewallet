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

defmodule EWalletAPI.V1.TransactionConsumptionViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.TransactionConsumptionView
  alias EWallet.Web.{Orchestrator, V1.TransactionConsumptionOverlay}

  describe "EWalletAPI.V1.TransactionConsumptionView.render/2" do
    test "renders transaction_consumption.json with correct structure" do
      {:ok, consumption} =
        :transaction_consumption
        |> insert()
        |> Orchestrator.one(TransactionConsumptionOverlay)

      result =
        render(
          TransactionConsumptionView,
          "transaction_consumption.json",
          transaction_consumption: consumption
        )

      # The serializer tests should cover data transformation already, so we only test that
      # the view builds the expected object and wraps the data into the expected response format.
      assert %{
               version: _,
               success: _,
               data: %{
                 object: "transaction_consumption"
               }
             } = result
    end
  end
end
