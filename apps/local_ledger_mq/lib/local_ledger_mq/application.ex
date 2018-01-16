defmodule LocalLedgerMQ.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      supervisor(RabbitMQRPC.Supervisor, [get_config(),
                                          LocalLedgerMQ.MQConsumer,
                                          :"local_ledger_mq.rabbitmq_rpc.supervisor"])
    ]

    opts = [strategy: :one_for_one, name: LocalLedgerMQ.Supervisor]
    :ok = :error_logger.add_report_handler(Sentry.Logger)
    Supervisor.start_link(children, opts)
  end

  defp get_config do
    Application.get_all_env(:local_ledger_mq)[:rabbitmq_rpc]
  end
end
