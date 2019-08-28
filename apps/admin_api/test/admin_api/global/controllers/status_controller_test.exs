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

defmodule AdminAPI.StatusControllerTest do
  use AdminAPI.ConnCase, async: false

  describe "GET request to /" do
    test "returns status ok" do
      original_version = Application.get_env(:ewallet, :version)
      _ = on_exit(fn -> Application.put_env(:ewallet, :version, original_version) end)
      _ = Application.put_env(:ewallet, :version, "0.9.9")

      response =
        build_conn()
        |> get(@base_dir <> "/")
        |> json_response(:ok)

      # Wonder where the ethereum status is from? It's `EthBlockchain.DumbAdapter`.
      assert response == %{
               "success" => true,
               "ewallet_version" => "0.9.9",
               "api_versions" => [
                 %{"name" => "v1", "media_type" => "application/vnd.omisego.v1+json"}
               ],
               "ethereum" => %{
                 "client_version" => "DumbAdapter/v4.2.0-c999068/linux/go1.9.2",
                 "eth_syncing" => false,
                 "last_seen_eth_block_number" => 14,
                 "network_id" => "99",
                 "peer_count" => 42
               }
             }
    end
  end
end
