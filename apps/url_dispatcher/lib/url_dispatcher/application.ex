defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  alias Plug.Adapters.Cowboy

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      {Cowboy, scheme: :http, plug: UrlDispatcher.Plug, options: [port: dispatcher_port()]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatcher_port do
    :url_dispatcher
    |> Application.get_env(:port)
    |> port_to_integer()
  end

  defp port_to_integer(port) when is_binary(port), do: String.to_integer(port)
  defp port_to_integer(port) when is_integer(port), do: port
end
