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

defmodule AdminAPI.Application do
  @moduledoc """
  AdminAPI's startup and shutdown functionalities
  """
  use Application
  alias AdminAPI.Endpoint
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:admin_api)

    settings = Application.get_env(:admin_api, :settings)
    Config.register_and_load(:admin_api, settings)

    EWallet.configure_socket_endpoints([AdminAPI.V1.Endpoint])

    # Always run AdminAPI.Endpoint and AdminAPI.V1.Endpoint in supervision tree
    # regardless whether UrlDispatcher is enabled or not, since UrlDispatcher
    # is not guarantee to be started, so we should not try to access the
    # :url_dispatcher env here.
    children = [
      supervisor(AdminAPI.Endpoint, []),
      supervisor(AdminAPI.V1.Endpoint, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdminAPI.Supervisor]

    case Logger.add_backend(Sentry.LoggerBackend) do
      {:ok, _} -> :ok
      {:error, :already_present} -> :ok
      error -> raise "Unable to add Sentry.LoggerBackend: #{inspect(error)}"
    end

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
