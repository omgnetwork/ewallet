defmodule EWalletAPI.V1.TransactionRequestConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.TransactionConsumptionGate
  alias EWallet.Web.V1.{
    ResponseSerializer,
    TransactionRequestConsumptionSerializer
  }

  def consume(conn, attrs) do
    attrs
    |> Map.put("idempotency_token", conn.assigns.idempotency_token)
    |> TransactionConsumptionGate.consume(&broadcast/1)
    |> respond(conn)
  end

  def consume_for_user(conn, attrs) do
    attrs = Map.put(attrs, "idempotency_token", conn.assigns.idempotency_token)

    conn.assigns.user
    |> TransactionConsumptionGate.consume(attrs, &broadcast/1)
    |> respond(conn)
  end

  defp broadcast(consumption) do
    EWalletAPI.Endpoint.broadcast(
      "transaction_request:#{consumption.transaction_request.id}",
      "transaction_request_confirmation",
      consumption
      |> TransactionRequestConsumptionSerializer.serialize()
      |> ResponseSerializer.serialize(success: true)
    )
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:ok, consumption}, conn) do
    render(conn, :transaction_request_consumption, %{
      transaction_request_consumption: consumption
    })
  end
end
