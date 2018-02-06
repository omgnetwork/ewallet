defmodule AdminPanel.Application do
  @moduledoc false
  use Application
  alias AdminPanel.Endpoint

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(AdminPanel.Endpoint, []),

      # Start your own worker by calling: AdminPanel.Worker.start_link(arg1, arg2, arg3)
      # worker(AdminPanel.Worker, [arg1, arg2, arg3]),

      worker(Phoenix.Endpoint.Watcher, [
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
    ]

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
