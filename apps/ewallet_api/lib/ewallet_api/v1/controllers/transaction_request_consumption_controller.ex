defmodule EWalletAPI.V1.TransactionRequestConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Transactions.Consumption

  def consume(conn, attrs) do
    conn.assigns.user
    |> Consumption.consume(conn.assigns.idempotency_token, attrs)
    |> respond(conn)
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
