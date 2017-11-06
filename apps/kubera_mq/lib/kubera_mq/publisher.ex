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

  def send(payload) do
    GenServer.call(__MODULE__, {:publish, payload})
  end

  def handle_call({:publish, payload}, _from, chan) do
    response = RabbitMQPublisher.call(chan, payload)
    {:reply, response, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end
end
