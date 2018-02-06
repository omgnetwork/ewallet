defmodule UrlDispatcher.Application do
  @moduledoc false
  use Application
  alias Plug.Adapters.Cowboy

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = Application.get_env(:url_dispatcher, :port)

    # List all child processes to be supervised
    children = [
      Cowboy.child_spec(:http, UrlDispatcher.Plug, [], [port: port])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: UrlDispatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
