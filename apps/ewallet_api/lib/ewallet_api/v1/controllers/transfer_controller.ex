defmodule EWalletAPI.V1.TransferController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.{ErrorHandler}
  alias EWallet.{TransactionGate, WalletFetcher}
  alias EWalletAPI.V1.TransactionView

  def transfer_for_user(
        conn,
        %{
          "idempotency_token" => idempotency_token,
          "to_address" => to_address,
          "token_id" => token_id,
          "amount" => amount
        } = attrs
      )
      when idempotency_token != nil and to_address != nil and token_id != nil and
             is_integer(amount) do
    conn.assigns.user
    |> WalletFetcher.get(attrs["from_address"])
    |> transfer_from_wallet(conn, attrs)
  end

  def transfer_for_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp transfer_from_wallet({:ok, from_wallet}, conn, attrs) do
    attrs
    |> Map.put("from_address", from_wallet.address)
    |> TransactionGate.process_with_addresses()
    |> respond_with(:transaction, conn)
  end

  defp transfer_from_wallet({:error, :user_wallet_not_found}, conn, _attrs) do
    handle_error(conn, :from_address_not_found)
  end

  defp transfer_from_wallet({:error, :user_wallet_mismatch}, conn, _attrs) do
    handle_error(conn, :from_address_mismatch)
  end

  defp transfer_from_wallet({:error, error}, conn, _attrs), do: handle_error(conn, error)

  defp respond_with({:ok, transaction, _balances, _token}, :transaction, conn) do
    conn
    |> put_view(TransactionView)
    |> render(:transaction, %{transaction: transaction})
  end

  defp respond_with({:error, code}, _, conn), do: handle_error(conn, code)

  defp respond_with({:error, _transfer, code, description}, _, conn) do
    handle_error(conn, code, description)
  end
end
