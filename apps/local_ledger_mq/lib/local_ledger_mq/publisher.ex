defmodule LocalLedgerMQ.Publisher do
  @moduledoc """
  Publishing logic for LocalLedgerMQ through RabbitMQ-RPC.
  """
  alias RabbitMQRPC.Publisher

  def publish(queue, payload, correlation_id) do
    send(%{
      queue: queue,
      payload: Poison.encode!(payload),
      correlation_id: correlation_id
    })
  end

  def publish(queue, payload) do
    send(%{
      queue: queue,
      payload: Poison.encode!(payload)
    })
  end

  defp send(data) do
    :"local_ledger_mq.publisher"
    |> Publisher.publish(data)
    |> handle_response()
  end

  defp handle_response({:ok, _correlation_id, payload}) do
    response = Poison.decode!(payload)

    case response["success"] do
      true ->
        {:ok, response["data"]}
      _ ->
        {:error, response["data"]["code"], response["data"]["description"]}
    end
  end
end
