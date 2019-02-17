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

defmodule LoadTester.Scenarios.AccountAll do
  @moduledoc """
  Test scenario for `/api/admin/account.all`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/account.all",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{},
      decode: :json,
      with_result: &store_accounts(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp store_accounts(session, result) do
    session
    |> update_assign(accounts: fn _ -> accounts_to_map(result.data.data) end)
    |> update_assign(master_account: fn _ -> get_master_account(result.data.data) end)
  end

  defp accounts_to_map(data) do
    Enum.reduce(data, %{}, fn account, acc ->
      Map.put(acc, account.name, account)
    end)
  end

  defp get_master_account(data) do
    Enum.find(data, fn account -> account.master end)
  end
end
