defmodule KuberaMQ.Publisher do
  @moduledoc """
  GenServer module publishing operations through RabbitMQ.
  """
  alias KuberaMQ.RabbitMQPublisher
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    RabbitMQPublisher.init
  end

  def send(payload, callback) do
    GenServer.call(__MODULE__, {:publish, payload, callback})
  end

  def handle_call({:publish, payload, callback}, _from, chan) do
    RabbitMQPublisher.call(chan, payload, callback)
    {:reply, %{}, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end
end
