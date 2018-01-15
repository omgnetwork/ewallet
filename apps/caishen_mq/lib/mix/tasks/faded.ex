defmodule Mix.Tasks.Faded do
  @moduledoc """
  Checks if Caishen is running.
  """
  use Mix.Task
  alias CaishenMQ.Publisher

  @shortdoc "Check if the application has finished booting."
  def run(_) do
    {:ok, _pid} = RabbitMQRPC.Publisher.start_link(%{
      url: Application.get_env(:rabbitmq_rpc, :url),
      exchange: Application.get_env(:rabbitmq_rpc, :exchange),
      publish_queues: Application.get_env(:rabbitmq_rpc, :publish_queues),
      consume_queues: Application.get_env(:rabbitmq_rpc, :consume_queues)
    })

    {:ok, nil} = Publisher.publish(
      Application.get_env(:caishen_mq, :mq_ledger_queue),
      %{operation: "v1.status.check"}
    )

    # credo:disable-for-next-line
    IO.inspect("Under The Sea.")
  end
end
