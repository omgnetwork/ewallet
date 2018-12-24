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

defmodule AdminAPI.V1.CategoryViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.CategoryView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.CategorySerializer

  describe "AdminAPI.V1.CategoryView.render/2" do
    test "renders category.json with correct response structure" do
      category = insert(:category)

      expected = %{
        version: @expected_version,
        success: true,
        data: CategorySerializer.serialize(category)
      }

      assert CategoryView.render("category.json", %{category: category}) == expected
    end

    test "renders categories.json with correct response structure" do
      category1 = insert(:category)
      category2 = insert(:category)

      paginator = %Paginator{
        data: [category1, category2],
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
        data: CategorySerializer.serialize(paginator)
      }

      assert CategoryView.render("categories.json", %{categories: paginator}) == expected
    end
  end
end
