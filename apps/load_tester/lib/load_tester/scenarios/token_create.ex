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

defmodule LoadTester.Scenarios.TokenCreate do
  @moduledoc """
  Test scenario for `/api/admin/token.create`.
  """
  use Chaperon.Scenario

  def run(session) do
    date = DateTime.to_iso8601(DateTime.utc_now())

    session
    |> post(
      "/api/admin/token.create",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        symbol: "LOAD" <> random_string(4),
        name: "A load test coin generated on #{date}",
        description: "desc",
        subunit_to_unit: 1_000_000_000_000_000_000,
        amount: 1_000_000 * 1_000_000_000_000_000_000
      },
      decode: :json,
      with_result: &store_token(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
    |> binary_part(0, length)
  end

  defp store_token(session, result) do
    session
    |> update_assign(token: fn _ -> result.data end)
  end
end
