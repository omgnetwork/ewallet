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

defmodule AdminPanel.Application do
  @moduledoc false
  use Application
  alias AdminPanel.Endpoint
  alias Phoenix.Endpoint.Watcher

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children =
      []
      |> supervise_endpoint()
      |> supervise_webpack_watch()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdminPanel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Start the endpoint when the application starts
  defp supervise_endpoint(children) do
    import Supervisor.Spec

    [supervisor(Endpoint, []) | children]
  end

  # Add webpack watch supervisor only if webpack watch is enabled,
  # and the application is being started as a server.
  defp supervise_webpack_watch(children) do
    if webpack_watch?() && server?() do
      [webpack_watch() | children]
    else
      children
    end
  end

  # Returns true when the config `:webpack_watch` is set to true,
  # and the command is not flagged with `--no-watch`.
  defp webpack_watch? do
    webpack_watch = Application.get_env(:admin_panel, :webpack_watch, true)
    start_with_no_watch = Application.get_env(:admin_panel, :start_with_no_watch, false)

    webpack_watch && !start_with_no_watch
  end

  defp server? do
    Application.get_env(:url_dispatcher, :serve_endpoints, false)
  end

  defp webpack_watch do
    import Supervisor.Spec

    worker(
      Watcher,
      [
        :yarn,
        [
          "build"
        ],
        [cd: Path.expand("../../assets/", __DIR__)]
      ],
      restart: :transient
    )
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
