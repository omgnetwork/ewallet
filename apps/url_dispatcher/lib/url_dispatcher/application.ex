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
end
