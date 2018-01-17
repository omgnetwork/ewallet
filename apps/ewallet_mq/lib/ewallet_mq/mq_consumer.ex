defmodule EWalletMQ.MQConsumer do
  @moduledoc """
  Consuming module for RabbitMQ-RPC.
  """
  def handle(payload, _correlation_id) do
    %{
      success: true,
      data: Poison.decode!(payload)
    }
    |> Poison.encode!()
  end
end
