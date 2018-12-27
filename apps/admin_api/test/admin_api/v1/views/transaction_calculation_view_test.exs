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

defmodule AdminAPI.V1.TransactionCalculationViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.TransactionCalculationView
  alias EWallet.Exchange.Calculation

  describe "render/2" do
    test "renders calculation.json with correct response structure" do
      pair = insert(:exchange_pair)

      calculation = %Calculation{
        from_amount: 1000,
        from_token: pair.from_token,
        to_amount: 2000,
        to_token: pair.to_token,
        actual_rate: pair.rate,
        pair: pair,
        calculated_at: NaiveDateTime.utc_now()
      }

      rendered =
        TransactionCalculationView.render("calculation.json", %{calculation: calculation})

      assert rendered.success == true
      assert rendered.data.object == "transaction_calculation"
    end
  end
end
