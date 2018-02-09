defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{TransactionRequest, TransactionRequestConsumption}
  alias EWalletDB.{User, MintedToken, Balance}

  def create(conn, %{
    "type" => _,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id,
    "address" => address,
  } = attrs) do
    with %User{} = user <- conn.assigns.user,
         %MintedToken{} = minted_token <- MintedToken.get(token_id) || :minted_token_not_found,
         %Balance{} = balance <- TransactionRequest.get_balance(user, address),
         {:ok, transaction_request} <- TransactionRequest.insert(user, minted_token, balance, attrs)
    do
      get(conn, %{"transaction_request_id" => transaction_request.id})
    else
      error when is_atom(error) -> handle_error(conn, error)
      {:error, changeset}       -> handle_error(conn, :invalid_parameter, changeset)
    end
  end
  def create(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  def get(conn, %{"transaction_request_id" => request_id}) do
    request_id
    |> TransactionRequest.get()
    |> respond(conn)
  end

  defp respond(nil, conn), do: handle_error(conn, :transaction_request_not_found)
  defp respond(request, conn) do
    render(conn, :transaction_request, %{transaction_request: request})
  end

  def consume(conn, %{
    "transaction_request_id" => request_id,
    "correlation_id" => _,
    "amount" => _,
    "address" => address,
    "metadata" => metadata
  } = attrs) do
    with %User{} = user <- conn.assigns.user,
         idempotency_token <- conn.assigns[:idempotency_token],
         request <- TransactionRequest.get(request_id) || :transaction_request_not_found,
         %Balance{} = balance <- TransactionRequest.get_balance(user, address),
         {:ok, consumption} <- TransactionRequestConsumption.insert(%{
           user: user,
           idempotency_token: idempotency_token,
           request: request,
           balance: balance,
           attrs: attrs
         })
    do
      request.type
      |> TransactionRequestConsumption.consume(consumption, metadata)
      |> respond_with_consumption(conn)
    else
      error when is_atom(error) -> handle_error(conn, error)
      {:error, changeset}       -> handle_error(conn, :invalid_parameter, changeset)
    end
  end

  defp respond_with_consumption({:ok, consumption}, conn) do
    render(conn, :transaction_request_consumption, %{transaction_request_consumption: consumption})
  end

  defp respond_with_consumption({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
end
