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

defmodule AdminAPI.StatusController do
  use AdminAPI, :controller
  alias EWallet.BlockchainHelper

  def status(conn, _attrs) do
    json(conn, %{
      success: true,
      api_versions: api_versions(),
      ewallet_version: Application.get_env(:ewallet, :version),
      ethereum: ethereum_status()
    })
  end

  defp api_versions do
    api_versions = Application.get_env(:admin_api, :api_versions)

    Enum.map(api_versions, fn {key, value} ->
      %{name: value[:name], media_type: key}
    end)
  end

  defp ethereum_status do
    case BlockchainHelper.call(:get_status) do
      {:ok, status} -> status
      _ -> false
    end
  end
end
