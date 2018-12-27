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

defmodule EWalletAPI.Application do
  @moduledoc """
  EWalletAPI's startup and shutdown functionalities
  """
  use Application
  alias EWallet.Web.Config
  alias EWalletAPI.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_api)

    settings = Application.get_env(:ewallet_api, :settings)
    EWalletConfig.Config.register_and_load(:ewallet_api, settings)

    Config.configure_cors_plug()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(EWalletAPI.Endpoint, []),
      supervisor(EWalletAPI.V1.Endpoint, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletAPI.Supervisor]

    :ok = :error_logger.add_report_handler(Sentry.Logger)

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
