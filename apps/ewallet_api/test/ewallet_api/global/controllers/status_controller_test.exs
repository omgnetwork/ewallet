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

defmodule EWalletAPI.StatusControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "GET request to root url" do
    test "returns status ok" do
      response =
        build_conn()
        |> get(@base_dir <> "/")
        |> json_response(:ok)

      assert response == %{
               "success" => true,
               "nodes" => 1,
               "services" => %{
                 "ewallet" => true,
                 "local_ledger" => true
               },
               "ewallet_version" => "1.1.0",
               "api_versions" => [
                 %{"name" => "v1", "media_type" => "application/vnd.omisego.v1+json"}
               ]
             }
    end
  end
end
