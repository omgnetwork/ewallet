defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Transactions.Request

  def create(conn, attrs) do
    conn.assigns.user
    |> Request.create(attrs)
    |> respond(conn)
  end

  def get(conn, %{"transaction_request_id" => request_id}) do
    request_id
    |> Request.get()
    |> respond(conn)
  end

  defp respond(nil, conn), do: handle_error(conn, :transaction_request_not_found)
  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:ok, request}, conn) do
    render(conn, :transaction_request, %{
      transaction_request: request
    })
  end
end
