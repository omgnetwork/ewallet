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

defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  require Logger
  alias EWallet.Helper
  alias Phoenix.Endpoint.CowboyWebSocket
  alias Plug.Adapters.Cowboy

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    DeferredConfig.populate(:url_dispatcher)

    serve_endpoints = Application.get_env(:url_dispatcher, :serve_endpoints)

    children =
      case Helper.to_boolean(serve_endpoints) do
        true ->
          dispatchers = []
          port = Application.get_env(:url_dispatcher, :port)
          _ = Logger.info("Running UrlDispatcher.Plug with Cowboy on port #{port}.")

          # This is the WebSocket endpoint for client API. They must come before
          # the catch-all route otherwise it would never get matched.
          dispatchers =
            dispatchers ++
              websocket_spec(
                "/api/client",
                EWalletAPI.WebSocket,
                EWalletAPI.V1.Endpoint
              )

          # This is the WebSocket endpoint for admin API. They must come before
          # the catch-all route otherwise it would never get matched.
          dispatchers =
            dispatchers ++
              websocket_spec(
                "/api/admin",
                AdminAPI.WebSocket,
                AdminAPI.V1.Endpoint
              )

          # This is a catch-all route and must always come last. UrlDispatcher
          # is responsible for all non-WebSockets requests, except the AdminPanel
          # which is handled inside AdminPanel.Application.
          dispatchers =
            dispatchers ++
              [
                {
                  :_,
                  Cowboy.Handler,
                  {UrlDispatcher.Plug, []}
                }
              ]

          # Finally, this is the actual children spec. We manually build the spec
          # instead of using Plug.Cowboy.child_spec since we need quite few
          # customizations of the dispatcher and thus it's simpler to just use
          # the Plug.Cowboy directly in the supervision tree.
          [
            {
              Plug.Cowboy,
              scheme: :http,
              plug: UrlDispatcher.Plug,
              options: [port: port, dispatch: [{:_, dispatchers}]]
            }
          ]

        _ ->
          _ = Logger.info("UrlDispatcher.Plug disabled.")
          []
      end

    _ = warn_unused_envs()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # WebSocket specs
  #

  defp websocket_spec(prefix, ws_handler, endpoint) do
    websocket_spec(prefix, ws_handler, endpoint, endpoint.__sockets__())
  end

  defp websocket_spec(prefix, ws_handler, endpoint, [{path, socket} | t]) do
    _ = Logger.info("Running #{inspect(endpoint)} WebSocket endpoint at #{prefix}#{path}.")

    [
      {
        "#{prefix}#{path}",
        CowboyWebSocket,
        {
          ws_handler,
          {
            endpoint,
            socket,
            :websocket
          }
        }
      }
      | websocket_spec(prefix, ws_handler, endpoint, t)
    ]
  end

  defp websocket_spec(_, _, _, []) do
    []
  end

  # Useful warning messages
  #

  defp warn_unused_envs do
    for {env, setting} <- Application.get_env(:ewallet, :env_migration_mapping) do
      case System.get_env(env) do
        nil ->
          :ok

        _ ->
          _ =
            Logger.warn("""
            `#{env}` is no longer used but is still present as an environment variable. \
            Please consider removing it and refer to `#{setting}` in the database's \
            `setting` table instead.
            """)
      end
    end
  end
end
