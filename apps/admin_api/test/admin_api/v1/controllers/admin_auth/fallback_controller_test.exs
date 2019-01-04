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

defmodule AdminAPI.V1.AdminAuth.FallbackControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/not_found" do
    test "returns correct error response for client-authtenticated requests" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:endpoint_not_found",
          "description" => "Endpoint not found.",
          "messages" => nil
        }
      }

      assert unauthenticated_request("/not_found") == expected
    end

    test "returns correct error response for user-authenticated requests" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:endpoint_not_found",
          "description" => "Endpoint not found.",
          "messages" => nil
        }
      }

      assert admin_user_request("/not_found") == expected
    end
  end
end
