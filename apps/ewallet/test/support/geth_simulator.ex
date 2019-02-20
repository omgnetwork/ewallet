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

defmodule EWallet.GethSimulator do
  @moduledoc """
  Simulates a geth node that responds to JSON-RPC request.
  """
  alias ABI.TypeEncoder
  alias Plug.Conn

  @total_supply "0x" <> ("totalSupply()" |> ABI.encode([]) |> Base.encode16(case: :lower))
  @name "0x" <> ("name()" |> ABI.encode([]) |> Base.encode16(case: :lower))
  @symbol "0x" <> ("symbol()" |> ABI.encode([]) |> Base.encode16(case: :lower))
  @decimals "0x" <> ("decimals()" |> ABI.encode([]) |> Base.encode16(case: :lower))

  @token_data %{
    total_supply: 140_245_398_000_000_000_000_000_000,
    name: "OmiseGO Mock Token by GethSimulator",
    symbol: "OMGMOCK",
    decimals: 18
  }

  def start do
    bypass = Bypass.open(port: 8545)

    Bypass.stub(bypass, "POST", "/", fn conn ->
      {:ok, body, conn} = Conn.read_body(conn)
      {:ok, body} = Jason.decode(body)

      result =
        case body["method"] do
          "net_version" -> "4"
          "eth_call" -> eth_call(body)
        end

      {:ok, response} =
        Jason.encode(%{
          id: 1234,
          jsonrpc: "2.0",
          result: result
        })

      Conn.resp(conn, 200, response)
    end)
  end

  def token_data, do: @token_data

  def eth_call(body) do
    case List.first(body["params"])["data"] do
      @total_supply -> encode(@token_data.total_supply)
      @name -> encode(@token_data.name)
      @symbol -> encode(@token_data.symbol)
      @decimals -> encode(@token_data.decimals)
    end
  end

  defp encode(value) when is_binary(value) do
    encode([{value}], [{:tuple, [:string]}])
  end

  defp encode(value) when is_integer(value) do
    encode([value], [{:uint, 256}])
  end

  defp encode(value, types) do
    "0x" <> (value |> TypeEncoder.encode_raw(types) |> Base.encode16(case: :lower))
  end
end
