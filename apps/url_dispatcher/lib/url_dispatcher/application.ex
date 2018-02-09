defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  require Logger
  alias Plug.Adapters.Cowboy

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = prepare_children([
      {:http, UrlDispatcher.Plug, port_for(:url_dispatcher)}
    ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port_for(app) do
    app
    |> Application.get_env(:port)
    |> port_to_integer()
  end

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port

  defp prepare_children(children) when is_list(children) do
    Enum.map(children, &prepare_children/1)
  end
  defp prepare_children({scheme, plug, port}) do
    Logger.info "Setting up #{inspect plug} with Cowboy running #{scheme} at port #{port}"
    {Cowboy, scheme: :http, plug: plug, options: [port: port]}
  end
end
