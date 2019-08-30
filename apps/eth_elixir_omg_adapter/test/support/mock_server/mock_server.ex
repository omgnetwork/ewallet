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

defmodule EthElixirOmgAdapter.MockServer do
  use Plug.Router

  alias EthElixirOmgAdapter.ResponseBody

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  @success_receiver "0x0000000000000000000000000000000000000001"

  def success_receiver, do: @success_receiver

  post("/transaction.create") do
    case conn.params do
      %{
        "owner" => sender,
        "fee" => %{"amount" => fee_amount, "currency" => fee_currency},
        "payments" => [
          %{"owner" => @success_receiver, "currency" => currency, "amount" => amount} | _
        ]
      } ->
        respond(
          conn,
          ResponseBody.transaction_create_success(
            sender,
            @success_receiver,
            amount,
            currency,
            fee_amount,
            fee_currency
          )
        )

      _ ->
        respond(conn, ResponseBody.transaction_create_failure())
    end
  end

  post("/transaction.submit_typed") do
    case conn.params do
      %{"message" => %{"output0" => %{"owner" => @success_receiver}}} ->
        respond(conn, ResponseBody.transaction_submit_typed_success())

      _ ->
        respond(conn, ResponseBody.transaction_submit_typed_failure())
    end
  end

  post("/post_request_test") do
    case conn.params do
      %{"expect" => "success", "data" => data} ->
        respond(conn, ResponseBody.post_request_success(data))

      %{"expect" => "handled_failure", "code" => code} ->
        respond(conn, ResponseBody.post_request_handled_failure(code))

      %{"expect" => "unhandled_failure"} ->
        respond(conn, ResponseBody.post_request_unhandled_failure(), 500)

      %{"expect" => "decoding_failure"} ->
        Plug.Conn.send_resp(conn, 200, ResponseBody.post_request_decoding_failure())
    end
  end

  defp respond(conn, body, code \\ 200) do
    Plug.Conn.send_resp(conn, code, Poison.encode!(body))
  end
end
