defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{
    TransactionRequestGate,
    TransactionRequestFetcher,
  }

  def create(conn, attrs) do
    attrs
    |> TransactionRequestGate.create()
    |> respond(conn)
  end

  def create_for_user(conn, attrs) do
    conn.assigns.user
    |> TransactionRequestGate.create(attrs)
    |> respond(conn)
  end

  def get(conn, %{"id" => id}) do
    id
    |> TransactionRequestFetcher.get()
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
