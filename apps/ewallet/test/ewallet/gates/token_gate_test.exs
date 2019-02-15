# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TokenGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TokenGate
  alias EWalletDB.Token
  alias Plug.Conn

  describe "import/1" do
    test "imports the token successfully" do
      bypass = Bypass.open(port: 8545)

      Bypass.expect(bypass, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        {:ok, body} = Jason.decode(body)

        assert conn.halted == false
        assert conn.method == "POST"
        assert conn.request_path == "/"

        result =
          case body["method"] do
            "net_version" ->
              "4"

            "eth_call" ->
              case List.first(body["params"])["data"] do
                # totalSupply()
                "0x18160ddd" -> "0x00000000000000000000000000000000000000000074021e42776ba058980000"
                # name()
                "0x06fdde03" -> "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000174f6d697365474f2052696e6b65627920546573746e6574000000000000000000"
                # symbol()
                "0x95d89b41" -> "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034f4d470000000000000000000000000000000000000000000000000000000000"
                # decimals()
                "0x313ce567" -> "0x0000000000000000000000000000000000000000000000000000000000000012"
              end
          end

        {:ok, response} =
          Jason.encode(%{
            id: 1234,
            jsonrpc: "2.0",
            result: result
          })

        Conn.resp(conn, 200, response)
      end)

      {res, token} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        }) |> IO.inspect()

      assert res == :ok
      assert %Token{} = token
    end
  end
end
