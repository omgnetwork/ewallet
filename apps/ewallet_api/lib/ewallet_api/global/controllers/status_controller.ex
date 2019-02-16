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

defmodule EWalletAPI.StatusController do
  use EWalletAPI, :controller
  alias LocalLedger.Status

  def status(conn, _attrs) do
    json(conn, %{
      success: true,
      nodes: node_count(),
      services: %{
        ewallet: true,
        local_ledger: local_ledger()
      },
      api_versions: api_versions(),
      ewallet_version: Application.get_env(:ewallet, :version)
    })
  end

  defp local_ledger do
    :ok == Status.check()
  end

  defp node_count do
    length(Node.list() ++ [Node.self()])
  end

  defp api_versions do
    api_versions = Application.get_env(:ewallet_api, :api_versions)

    Enum.map(api_versions, fn {key, value} ->
      %{name: value[:name], media_type: key}
    end)
  end
end
