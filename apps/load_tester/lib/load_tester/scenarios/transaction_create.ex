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

defmodule LoadTester.Scenarios.TransactionCreate do
  @moduledoc """
  Test scenario for `/api/admin/transaction.create`.
  """
  use Chaperon.Scenario

  def init(session) do
    rate = :load_tester |> Application.get_env(:total_requests) |> String.to_integer()
    interval = :load_tester |> Application.get_env(:duration) |> String.to_integer()

    session
    |> assign(rate: rate)
    |> assign(interval: interval)
    |> ok()
  end

  def run(session) do
    session
    |> cc_spread(
      :do_run,
      session.assigned.rate,
      session.assigned.interval * 1000
    )
  end

  def do_run(session) do
    from_account = get_master_account(session)
    to_account = get_non_master_account(session)
    token = config(session, :token)
    mint_amount = round(:rand.uniform() * token.subunit_to_unit)

    session
    |> post(
      "/api/admin/transaction.create",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        idempotency_token: 9_999_999 |> :rand.uniform() |> to_string(),
        from_account_id: from_account.id,
        to_account_id: to_account.id,
        token_id: token.id,
        amount: mint_amount,
        metadata: %{}
      }
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp get_master_account(session) do
    config(session, :master_account)
  end

  defp get_non_master_account(session) do
    config(session, :non_master_account)
  end
end
