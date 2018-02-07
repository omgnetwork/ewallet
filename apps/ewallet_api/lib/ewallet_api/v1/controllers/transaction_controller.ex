defmodule EWalletAPI.V1.TransactionRequestController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWalletDB.{TransactionRequest, User, MintedToken, Balance}

  def create(conn, %{
    "type" => _,
    "correlation_id" => _,
    "amount" => _,
    "token_id" => token_id,
    "address" => address,
  } = attrs) do
    with %User{} = user <- conn.assigns.user,
         %MintedToken{} = minted_token <- MintedToken.get(token_id) || :minted_token_not_found,
         balance <- Balance.get(address),
         {:ok, request} <- insert_transaction(attrs, user, minted_token, balance)
    do
      request = TransactionRequest.get(request.id, preload: [:minted_token])
      render(conn, :transaction_request, %{transaction_request: request})
    else
      error when is_atom(error) ->
        handle_error(conn, error)
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end
  def create(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp insert_transaction(attrs, user, minted_token, balance) do
    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: attrs["amount"],
      user_id: user.id,
      minted_token_id: minted_token.id,
      balance_address: (if balance, do: balance.address, else: nil)
    })
  end
end
