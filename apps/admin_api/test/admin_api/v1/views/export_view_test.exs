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

defmodule AdminAPI.V1.ExportViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.ExportView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.ExportSerializer

  describe "render/2" do
    test "renders export.json with correct response structure" do
      export = insert(:export)

      expected = %{
        version: @expected_version,
        success: true,
        data: ExportSerializer.serialize(export)
      }

      assert ExportView.render("export.json", %{export: export}) == expected
    end

    test "renders exports.json with correct response structure" do
      export_1 = insert(:export)
      export_2 = insert(:export)

      paginator = %Paginator{
        data: [export_1, export_2],
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
        data: ExportSerializer.serialize(paginator)
      }

      assert ExportView.render("exports.json", %{exports: paginator}) == expected
    end
  end
end
