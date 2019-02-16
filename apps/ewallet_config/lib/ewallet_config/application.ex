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

defmodule EWalletConfig.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Appsignal.Ecto

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_config)

    ActivityLogger.configure(%{
      EWalletConfig.StoredSetting => %{type: "setting", identifier: :id}
    })

    :telemetry.attach(
      "appsignal-ecto",
      [:ewallet_config, :repo, :query],
      &Ecto.handle_event/4,
      nil
    )

    # List all child processes to be supervised
    children = [
      supervisor(EWalletConfig.Repo, []),
      supervisor(EWalletConfig.Config, [[named: true]]),
      supervisor(EWalletConfig.Vault, []),
      supervisor(EWalletConfig.FileStorageSupervisor, []),
      {DynamicSupervisor, name: EWalletConfig.DynamicSupervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletConfig.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
