defmodule KuberaMQ.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      supervisor(RabbitMQRPC.Supervisor, [get_config(), KuberaMQ.MQConsumer])
    ]

    opts = [strategy: :one_for_one, name: KuberaMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_config do
    %{
      url: Application.get_env(:kubera_mq, :mq_url),
      exchange: Application.get_env(:kubera_mq, :mq_exchange),
      publish_queues: Application.get_env(:kubera_mq, :mq_publish_queues),
      consume_queues: Application.get_env(:kubera_mq, :mq_consume_queues)
    }
  end
end
