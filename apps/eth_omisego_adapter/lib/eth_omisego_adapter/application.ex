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

defmodule EthOmiseGOAdapter.Application do
  @moduledoc false
  use Application
  alias EWalletConfig.Config

  @doc """
  Starts `EthOmiseGOAdapter.Application`. It doesn't start any child process since
  the `EthOmiseGOAdapter` code get started/called by other subapps. However, we still need
  this `EthOmiseGOAdapter.Application.start/2` to do configurations at startup.
  """
  def start(_type, _args) do
    settings = Application.get_env(:eth_omisego_adapter, :settings)
    _ = Config.register_and_load(:eth_omisego_adapter, settings)

    children = []
    Supervisor.start_link(children, name: EthOmiseGOAdapter.Supervisor, strategy: :one_for_one)
  end
end
