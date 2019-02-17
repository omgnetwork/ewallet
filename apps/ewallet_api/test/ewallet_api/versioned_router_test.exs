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

defmodule EWalletAPI.VersionedRouterTest do
  use EWalletAPI.ConnCase, async: true

  # Potential candidate to be moved to a shared library

  describe "versioned router" do
    test "accepts v1+json requests" do
      response =
        build_conn()
        |> put_req_header("accept", "application/vnd.omisego.v1+json")
        |> post(@base_dir <> "/status")
        |> json_response(:ok)

      assert response == %{"success" => true}
    end

    test "rejects unrecognized version requests" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_version",
          "description" =>
            "Invalid API version. Given: 'application/vnd.omisego.invalid_ver+json'.",
          "messages" => nil
        }
      }

      response =
        build_conn()
        |> put_req_header("accept", "application/vnd.omisego.invalid_ver+json")
        |> post(@base_dir <> "/status")
        |> json_response(:ok)

      assert response == expected
    end
  end
end
