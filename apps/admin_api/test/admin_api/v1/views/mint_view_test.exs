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

defmodule AdminAPI.V1.MintViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.MintView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.MintSerializer

  describe "render/2" do
    test "renders mint.json with the given mint" do
      mint = insert(:mint)

      expected = %{
        version: @expected_version,
        success: true,
        data: MintSerializer.serialize(mint)
      }

      assert MintView.render("mint.json", %{mint: mint}) == expected
    end

    test "renders mints.json with the given mints" do
      mint_1 = insert(:mint)
      mint_2 = insert(:mint)

      paginator = %Paginator{
        data: [mint_1, mint_2],
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
        data: MintSerializer.serialize(paginator)
      }

      assert MintView.render("mints.json", %{mints: paginator}) == expected
    end
  end
end
