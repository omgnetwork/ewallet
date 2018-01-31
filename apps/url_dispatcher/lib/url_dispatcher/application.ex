defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  alias Plug.Adapters.Cowboy

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: UrlDispatcher.Worker.start_link(arg)
      # {UrlDispatcher.Worker, arg},
      Cowboy.child_spec(:http, UrlDispatcher.Router, [], port: 8080)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
