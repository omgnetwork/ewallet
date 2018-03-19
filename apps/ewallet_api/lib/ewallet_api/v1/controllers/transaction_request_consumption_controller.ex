defmodule EWalletAPI.V1.TransactionRequestConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.TransactionConsumptionGate

  def consume(conn, attrs) do
    attrs
    |> Map.put("idempotency_token", conn.assigns.idempotency_token)
    |> TransactionConsumptionGate.consume()
    |> respond(conn)
  end

  def consume_for_user(conn, attrs) do
    attrs = Map.put(attrs, "idempotency_token", conn.assigns.idempotency_token)

    conn.assigns.user
    |> TransactionConsumptionGate.consume(attrs)
    |> respond(conn)
  end

  def confirm(conn, %{"id" => id}) do
    id
    |> TransactionConsumptionGate.confirm()
    |> respond(conn)
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, consumption, code, description}, conn) do
    dispatch_change_event(consumption)
    handle_error(conn, code, description)
  end
  defp respond({:ok, consumption}, conn) do
    dispatch_change_event(consumption)
    render(conn, :transaction_request_consumption, %{
      transaction_request_consumption: consumption
    })
  end

  defp dispatch_change_event(consumption) do
    EWallet.Event.dispatch(:transaction_request_consumption_change, %{
      consumption: consumption
    })
  end
end
