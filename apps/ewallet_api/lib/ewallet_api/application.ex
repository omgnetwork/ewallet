defmodule EWalletAPI.Application do
  @moduledoc """
  EWalletAPI's startup and shutdown functionalities
  """
  use Application
  alias EWalletAPI.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_api)

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(EWalletAPI.Endpoint, []),
      supervisor(EWalletAPI.V1.Endpoint, [])
      # Start your own worker by calling:
      #   EWalletAPI.Worker.start_link(arg1, arg2, arg3)
      # worker(EWalletAPI.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletAPI.Supervisor]

    :ok = :error_logger.add_report_handler(Sentry.Logger)

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
