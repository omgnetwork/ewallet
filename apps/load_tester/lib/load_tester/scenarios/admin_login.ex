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

defmodule LoadTester.Scenarios.AdminLogin do
  @moduledoc """
  Test scenario for `/api/admin/admin.login`.
  """
  use Chaperon.Scenario

  def run(session) do
    session
    |> post(
      "/api/admin/admin.login",
      headers: %{
        "Accept" => "application/vnd.omisego.v1+json"
      },
      json: %{
        "email" => Application.get_env(:load_tester, :email),
        "password" => Application.get_env(:load_tester, :password)
      },
      decode: :json,
      with_result: &store_auth_token(&1, &2)
    )
  end

  def store_auth_token(session, result) do
    session
    |> update_assign(auth_token: fn _ -> result.data.authentication_token end)
    |> update_assign(user_id: fn _ -> result.data.user_id end)
    |> update_assign(user: fn _ -> result.data.user end)
  end
end
