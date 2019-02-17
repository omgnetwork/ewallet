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

defmodule AdminAPI.V1.TransactionConsumptionViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.TransactionConsumptionView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.TransactionConsumptionSerializer
  alias EWalletDB.Helpers.Preloader

  describe "render/2" do
    test "renders transaction_consumption.json with the given transaction_consumption" do
      consumption =
        :transaction_consumption
        |> insert()
        |> Preloader.preload([:token, :transaction_request])

      expected = %{
        version: @expected_version,
        success: true,
        data: TransactionConsumptionSerializer.serialize(consumption)
      }

      assert TransactionConsumptionView.render("transaction_consumption.json", %{
               transaction_consumption: consumption
             }) == expected
    end

    test "renders transaction_consumptions.json with the given transaction_consumptions" do
      consumption_1 =
        :transaction_consumption
        |> insert()
        |> Preloader.preload([:token, :transaction_request])

      consumption_2 =
        :transaction_consumption
        |> insert()
        |> Preloader.preload([:token, :transaction_request])

      paginator = %Paginator{
        data: [consumption_1, consumption_2],
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
        data: TransactionConsumptionSerializer.serialize(paginator)
      }

      assert TransactionConsumptionView.render("transaction_consumptions.json", %{
               transaction_consumptions: paginator
             }) == expected
    end
  end
end
