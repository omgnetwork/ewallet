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
  require Logger
  alias AdminPanel.Endpoint
  alias Phoenix.Endpoint.Watcher
  alias Utils.Helpers.Normalize
  import Supervisor.Spec

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    DeferredConfig.populate(:admin_panel)

    # Always run AdminPanel.Endpoint as part of supervision tree
    # regardless whether UrlDispatcher is enabled or not, since UrlDispatcher
    # is not guarantee to be started, so we should not try to access the
    # :url_dispatcher env here.
    children = [supervisor(Endpoint, [])]

    # Simply spawn a webpack process as part of supervision tree in case
    # webpack_watch is enabled. It probably doesn't make sense to watch
    # webpack without enabling endpoint serving, but we allow it anyway.
    webpack_watch = Application.get_env(:admin_panel, :webpack_watch)

    children =
      children ++
        case Normalize.to_boolean(webpack_watch) do
          true ->
            _ = Logger.info("Enabling webpack watcher.")

            # Webpack watcher is only for development, and rely on assets path
            # being present (which doesn't in production); so this is using
            # __DIR__ to make it expand to source path rather than compiled path.
            [
              worker(
                Watcher,
                [:yarn, ["build"], [cd: Path.expand("../../assets/", __DIR__)]],
                restart: :transient
              )
            ]

          _ ->
            []
        end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdminPanel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
