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

defmodule AdminAPI.V1.TokenViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.TokenView
  alias EWallet.Web.Paginator
  alias Utils.Helpers.DateFormatter

  describe "AdminAPI.V1.TokenView.render/2" do
    test "renders token.json with correct response structure" do
      token = insert(:token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "token",
          id: token.id,
          symbol: token.symbol,
          name: token.name,
          metadata: %{},
          encrypted_metadata: %{},
          enabled: true,
          subunit_to_unit: token.subunit_to_unit,
          created_at: DateFormatter.to_iso8601(token.inserted_at),
          updated_at: DateFormatter.to_iso8601(token.updated_at)
        }
      }

      assert TokenView.render("token.json", %{token: token}) == expected
    end

    test "renders tokens.json with correct response structure" do
      token1 = insert(:token)
      token2 = insert(:token)

      paginator = %Paginator{
        data: [token1, token2],
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
        data: %{
          object: "list",
          data: [
            %{
              object: "token",
              id: token1.id,
              symbol: token1.symbol,
              name: token1.name,
              metadata: %{},
              encrypted_metadata: %{},
              enabled: true,
              subunit_to_unit: token1.subunit_to_unit,
              created_at: DateFormatter.to_iso8601(token1.inserted_at),
              updated_at: DateFormatter.to_iso8601(token1.updated_at)
            },
            %{
              object: "token",
              id: token2.id,
              symbol: token2.symbol,
              name: token2.name,
              metadata: %{},
              encrypted_metadata: %{},
              enabled: true,
              subunit_to_unit: token2.subunit_to_unit,
              created_at: DateFormatter.to_iso8601(token2.inserted_at),
              updated_at: DateFormatter.to_iso8601(token2.updated_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: false
          }
        }
      }

      assert TokenView.render("tokens.json", %{tokens: paginator}) == expected
    end
  end
end
