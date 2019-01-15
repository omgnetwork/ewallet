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
  alias EWallet.Helper
  alias Phoenix.Endpoint.Watcher
  import Supervisor.Spec

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    DeferredConfig.populate(:admin_panel)

    children = []

    # AdminPanel.Endpoint is not being served as part of UrlDispatcher.Plug
    # so they're handled here separately.
    serve_endpoints = Application.get_env(:url_dispatcher, :serve_endpoints)

    children =
      children ++
        case Helper.to_boolean(serve_endpoints) do
          true ->
            [supervisor(Endpoint, [])]

          _ ->
            []
        end

    # Simply spawn a webpack process as part of supervision tree in case
    # webpack_watch is enabled. It probably doesn't make sense to watch
    # webpack without enabling endpoint serving, but we allow it anyway.
    webpack_watch = Application.get_env(:admin_panel, :webpack_watch)

    children =
      children ++
        case Helper.to_boolean(webpack_watch) do
          true ->
            _ = Logger.info("Enabling webpack watcher.")

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
