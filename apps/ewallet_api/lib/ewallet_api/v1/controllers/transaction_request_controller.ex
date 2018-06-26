defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler

  alias EWallet.{
    TransactionRequestGate,
    TransactionRequestFetcher
  }

  def create_for_user(conn, attrs) do
    conn.assigns.user
    |> TransactionRequestGate.create(attrs)
    |> respond(conn)
  end

  def get(conn, %{"formatted_id" => formatted_id}) do
    formatted_id
    |> TransactionRequestFetcher.get()
    |> respond(conn)
  end

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
