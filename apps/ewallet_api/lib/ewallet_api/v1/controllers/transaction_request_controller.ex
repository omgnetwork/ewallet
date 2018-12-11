defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler

  alias EWallet.{
    TransactionRequestFetcher,
    TransactionRequestGate,
    TransactionRequestPolicy
  }

  @spec create_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_for_user(conn, attrs) do
    conn.assigns.end_user
    |> TransactionRequestGate.create(attrs)
    |> respond(conn)
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"formatted_id" => formatted_id}) do
    with {:ok, request} <- TransactionRequestFetcher.get(formatted_id),
         :ok <- permit(:get, conn.assigns, request) do
      respond({:ok, request}, conn)
    else
      {:error, :transaction_request_not_found} ->
        respond({:error, :unauthorized}, conn)

      error ->
        respond(error, conn)
    end
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

  @spec permit(:all | :create | :get | :update, map(), %EWalletDB.TransactionRequest{}) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, request) do
    Bodyguard.permit(TransactionRequestPolicy, action, params, request)
  end
end
