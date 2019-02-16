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

defmodule EWalletAPI.ErrorViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.ErrorView

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  describe "EWalletAPI.ErrorView.render/2" do
    # Potential candidate to be moved to a shared library

    test "renders 500.json with correct structure given a custom description" do
      assigns = %{
        reason: %{
          message: "Custom assigned error description"
        }
      }

      expected = %{
        version: "1",
        success: false,
        data: %{
          object: "error",
          code: "server:internal_server_error",
          description: "Custom assigned error description",
          messages: nil
        }
      }

      assert render(ErrorView, "500.json", assigns) == expected
    end

    test "renders invalid template as server error" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          object: "error",
          code: "server:internal_server_error",
          description: "Something went wrong on the server",
          messages: nil
        }
      }

      assert render(ErrorView, "invalid_template.json", []) == expected
    end
  end
end
