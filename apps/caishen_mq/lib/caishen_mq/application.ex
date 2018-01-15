defmodule CaishenMQ.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      supervisor(RabbitMQRPC.Supervisor, [get_config(), CaishenMQ.MQConsumer])
      # Starts a worker by calling: CaishenMQ.Worker.start_link(arg)
      # {CaishenMQ.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CaishenMQ.Supervisor]

    :ok = :error_logger.add_report_handler(Sentry.Logger)

    Supervisor.start_link(children, opts)
  end

  defp get_config do
    :rabbitmq_rpc
    |> Application.get_all_env()
    |> Enum.into(%{})
  end
end
