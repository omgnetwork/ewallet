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

defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  require Logger
  alias Plug.Adapters.Cowboy
  alias UrlDispatcher.SocketDispatcher

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    DeferredConfig.populate(:url_dispatcher)

    # List all child processes to be supervised
    children =
      prepare_children([
        {
          :http,
          UrlDispatcher.Plug,
          port_for(:url_dispatcher),
          websockets_dispatcher() ++ [http_dispatcher()]
        }
      ])

    _ = warn_unused_envs()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp websockets_dispatcher do
    _ = Logger.info("Setting up websockets dispatchers...")
    SocketDispatcher.websockets()
  end

  defp http_dispatcher do
    {:_, Plug.Adapters.Cowboy.Handler, {UrlDispatcher.Plug, []}}
  end

  defp port_for(app) do
    app
    |> Application.get_env(:port)
    |> port_to_integer()
  end

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port

  defp prepare_children(children) when is_list(children) do
    if server?(), do: Enum.map(children, &prepare_children/1), else: []
  end

  defp prepare_children({scheme, plug, port, dispatchers}) do
    _ = Logger.info("Running #{inspect(plug)} with Cowboy #{scheme} on port #{port}")

    Cowboy.child_spec(
      scheme,
      plug,
      [],
      port: port,
      dispatch: [{:_, dispatchers}]
    )
  end

  defp server? do
    Application.get_env(:url_dispatcher, :serve_endpoints, false)
  end

  defp warn_unused_envs do
    mapping = Application.get_env(:ewallet, :env_migration_mapping)

    Enum.each(mapping, fn {env_name, setting_name} ->
      case System.get_env(env_name) do
        nil ->
          :noop

        _ ->
          _ =
            Logger.warn("""
            `#{env_name}` is no longer used but is still present as an environment variable. \
            Please consider removing it and refer to `#{setting_name}` in the database's `setting` table instead. \
            Alternatively, you may run `mix #{Mix.Task.task_name(Mix.Tasks.Omg.Migrate.Settings)}` \
            from the command line to migrate all your environment variable settings to the database at once. \
            """)
      end
    end)
  end
end
