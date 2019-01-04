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

defmodule AdminAPI.V1.ExchangePairViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.ExchangePairView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.ExchangePairSerializer

  describe "render/2" do
    test "renders exchange_pair.json with correct response structure" do
      exchange_pair = insert(:exchange_pair)

      expected = %{
        version: @expected_version,
        success: true,
        data: ExchangePairSerializer.serialize(exchange_pair)
      }

      rendered = ExchangePairView.render("exchange_pair.json", %{exchange_pair: exchange_pair})
      assert rendered == expected
    end

    test "renders exchange_pairs.json with correct response structure" do
      exchange_pair1 = insert(:exchange_pair)
      exchange_pair2 = insert(:exchange_pair)

      paginator = %Paginator{
        data: [exchange_pair1, exchange_pair2],
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
        data: ExchangePairSerializer.serialize(paginator)
      }

      rendered = ExchangePairView.render("exchange_pairs.json", %{exchange_pairs: paginator})
      assert rendered == expected
    end
  end
end
