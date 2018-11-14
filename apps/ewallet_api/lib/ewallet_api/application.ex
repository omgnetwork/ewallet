defmodule EWalletAPI.Application do
  @moduledoc """
  EWalletAPI's startup and shutdown functionalities
  """
  use Application
  alias EWallet.Web.Config
  alias EWalletAPI.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_api)

    settings = Application.get_env(:ewallet_api, :settings)
    EWalletConfig.Config.register_and_load(:ewallet_api, settings)

    Config.configure_cors_plug()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(EWalletAPI.Endpoint, []),
      supervisor(EWalletAPI.V1.Endpoint, [])
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
