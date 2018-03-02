defmodule AdminPanel.Application do
  @moduledoc false
  use Application
  alias AdminPanel.Endpoint
  alias Phoenix.Endpoint.Watcher

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Endpoint, [])
    ]

    # Start `webpack watch` only if the config is set
    children = if webpack_watch?(), do: children ++ [webpack_watch()], else: children

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

  defp webpack_watch?, do: Application.get_env(:admin_panel, :webpack_watch, false)

  defp webpack_watch do
    import Supervisor.Spec

    worker(Watcher, [
      :yarn,
      [
        "webpack",
        "--watch-stdin",
        "--color",
        "--progress",
        "--config", "config/webpack.dev.js"
      ],
      [cd: Path.expand("../../assets/", __DIR__)]
    ],
    restart: :transient)
  end
end
