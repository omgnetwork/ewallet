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

defmodule LoadTester.Scenarios.AccountGetWallets do
  @moduledoc """
  Test scenario for `/api/admin/account.get_wallets`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/account.get_wallets",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json",
        "Authorization" => auth_header_content(session)
      },
      json: %{
        id: config(session, :master_account).id
      },
      decode: :json,
      with_result: &store_master_wallets(&1, &2)
    )
  end

  defp auth_header_content(session) do
    "OMGAdmin " <> Base.url_encode64(session.config.user_id <> ":" <> session.config.auth_token)
  end

  defp store_master_wallets(session, result) do
    session
    |> update_assign(master_wallets: fn _ -> result.data.data end)
  end
end
