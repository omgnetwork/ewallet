defmodule EWalletAPI.V1.TransferController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.{ErrorHandler}
  alias EWallet.{BalanceFetcher, TransactionGate, WalletFetcher}
  alias EWalletAPI.V1.{WalletView, TransactionView}

  def transfer_for_user(conn, attrs)
    attrs
    |> Map.put("from_user_id", conn.assigns.user.id)
    |> TransactionGate.create()
    |> respond_with(:transaction, conn)
  end

  def transfer_for_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp transfer_from_wallet({:ok, from_wallet}, conn, attrs) do
    attrs
    |> Map.put("from_user_id", from_wallet.address)
    |> Map.put("from_address", from_wallet.address)
    |> TransactionGate.create()
    |> respond_with(:transaction, conn)
  end

  defp transfer_from_wallet({:error, :user_wallet_not_found}, conn, _attrs) do
    handle_error(conn, :from_address_not_found)
  end

  defp transfer_from_wallet({:error, :user_wallet_mismatch}, conn, _attrs) do
    handle_error(conn, :from_address_mismatch)
  end

  defp transfer_from_wallet({:error, error}, conn, _attrs), do: handle_error(conn, error)

  defp respond_with({:ok, transaction}, :transaction, conn) do
    conn
    |> put_view(TransactionView)
    |> render(:transaction, %{transaction: transaction})
  end

  defp respond_with({:ok, transaction}, :wallets, conn) do
    wallets =
      Enum.map(wallets, fn wallet ->
        case BalanceFetcher.get(token.id, wallet) do
          {:ok, address} -> address
          error -> error
        end
      end)

    case Enum.find(wallets, fn e -> match?({:error, _code, _description}, e) end) do
      nil -> respond({:ok, wallets}, conn)
      error -> error
    end
  end

  defp respond_with({:error, code}, _, conn), do: handle_error(conn, code)

  defp respond_with({:error, _transfer, code, description}, _, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:ok, wallets}, conn) do
    conn
    |> put_view(WalletView)
    |> render(:wallets, %{wallets: wallets})
  end

  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
