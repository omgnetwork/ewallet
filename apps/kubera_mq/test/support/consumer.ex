defmodule KuberaMQ.Consumer do
  @moduledoc """
  GenServer module listening handling communication with RabbitMQ.
  """
  alias KuberaMQ.RabbitMQClient

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    RabbitMQClient.init
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as
  # after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, meta}, chan) do
    spawn fn ->
      RabbitMQClient.consume(chan, payload, meta)
    end

    {:noreply, chan}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = RabbitMQClient.init
    {:noreply, chan}
  end
end
