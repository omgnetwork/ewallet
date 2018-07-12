defmodule EWalletAPI.Application do
  @moduledoc """
  EWalletAPI's startup and shutdown functionalities
  """
  use Application
  alias EWalletAPI.Endpoint

  def start(_type, _args) do
    import Supervisor.Spec
    spec_path = Path.expand("../../priv/spec.yaml", __DIR__)

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(EWalletAPI.Endpoint, []),
      supervisor(EWalletAPI.V1.Endpoint, []),
      supervisor(EWallet.Web.APIDocs.JSONGenerator, [spec_path])
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
