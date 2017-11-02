defmodule KuberaMQ.RabbitMQClient do
  @moduledoc """
  RabbitMQ interface handling the connection (and re-connection) and
  initiating the operation.
  Heavily inspired from https://github.com/pma/amqp/tree/v0.3
  """
  use AMQP

  def init do
    config = get_config()

    case Connection.open(config.url) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        open_channel(conn, config)
      {:error, _} ->
        :timer.sleep(5_000)
        init()
    end
  end

  def consume(channel, payload, meta) do
    payload = Poison.decode!(payload)
    reply(channel, meta, Poison.encode!(%{success: true, data: payload}))
  rescue
    exception ->
      reply(channel, meta, Poison.encode!(%{error: exception}))
  end

  defp reply(channel, meta, payload) do
    Basic.publish channel,
                  meta.exchange,
                  meta.reply_to,
                  payload,
                  content_type: "application/json",
                  correlation_id: meta.correlation_id
    Basic.ack(channel, meta.delivery_tag)
  end

  defp open_channel(conn, config) do
    {:ok, chan} = Channel.open(conn)
    Basic.qos(chan, prefetch_count: 1)
    error_queue = setup_error_queue(chan, config)
    Queue.declare(chan, config.queue, durable: true, persistence: true,
                  arguments: [{"x-dead-letter-exchange", :longstr, ""},
                              {"x-dead-letter-routing-key", :longstr,
                               error_queue}])

    Exchange.declare(chan, config.exchange)
    Queue.bind(chan, config.queue, config.exchange, routing_key: config.queue)
    {:ok, _consumer_tag} = Basic.consume(chan, config.queue)
    {:ok, chan}
  end

  defp setup_error_queue(chan, config) do
    Queue.declare(chan, config.error_queue, durable: true, persistence: true)
    config.error_queue
  end

  defp get_config do
    %{
      url: Application.get_env(:kubera_mq, :mq_url),
      exchange: Application.get_env(:kubera_mq, :mq_exchange),
      queue: Application.get_env(:kubera_mq, :mq_queue),
      error_queue: Application.get_env(:kubera_mq, :mq_error_queue)
    }
  end
end
