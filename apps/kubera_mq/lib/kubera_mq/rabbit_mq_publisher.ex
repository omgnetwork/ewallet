defmodule KuberaMQ.RabbitMQPublisher do
  @moduledoc """
  Provider submitting operations through RabbitMQ.
  """
  alias AMQP.{Connection, Channel, Queue, Basic, Exchange}
  alias Ecto.UUID

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

  def call(chan, payload, callback) do
    config = get_config()
    correlation_id = generate_correlation_id()

    Basic.publish chan,
                  config.exchange,
                  config.queue,
                  Poison.encode!(payload),
                  content_type: "application/json",
                  reply_to: setup_tmp_queue(chan, config),
                  correlation_id: correlation_id

    wait_for_messages(chan, correlation_id, callback)
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
    {:ok, chan}
  end

  defp wait_for_messages(_channel, correlation_id, callback) do
    receive do
      {:basic_deliver, payload, %{correlation_id: ^correlation_id}} ->
        callback.(Poison.decode!(payload))
    end
  end

  defp setup_error_queue(chan, config) do
    Queue.declare(chan, config.error_queue, durable: true, persistence: true)
    config.error_queue
  end

  defp setup_tmp_queue(chan, config) do
    {:ok, %{queue: queue_name}} = Queue.declare(chan, "", exclusive: true)
    Exchange.declare chan, config.exchange
    Queue.bind chan, queue_name, config.exchange, routing_key: queue_name
    Basic.consume(chan, queue_name, nil, no_ack: true)

    queue_name
  end

  defp generate_correlation_id do
    UUID.generate()
  end

  defp get_config do
    %{
      url: Application.get_env(:kubera_mq, :mq_url),
      exchange: Application.get_env(:kubera_mq, :mq_exchange),
      queue: Application.get_env(:kubera_mq, :mq_queue),
      reply_queue: Application.get_env(:kubera_mq, :mq_reply_queue),
      error_queue: Application.get_env(:kubera_mq, :mq_error_queue)
    }
  end
end
