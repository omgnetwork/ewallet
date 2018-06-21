defmodule AdminAPI.V1.TransferController do
  use AdminAPI, :controller
  import AdminAPI.V1.{ErrorHandler}
  alias EWallet.{BalanceFetcher, TransactionGate}
  alias AdminAPI.V1.{WalletView, TransactionView}

  def transfer(
        conn,
        %{
          "idempotency_token" => idempotency_token,
          "from_address" => from_address,
          "to_address" => to_address,
          "token_id" => token_id,
          "amount" => amount
        } = attrs
      )
      when idempotency_token != nil and from_address != nil
      when to_address != nil and token_id != nil and is_integer(amount) do
    attrs
    |> TransactionGate.create()
    |> respond_with(:wallets, conn)
  end

  def transfer(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  def credit(conn, attrs), do: credit_or_debit(conn, TransactionGate.credit_type(), attrs)
  def debit(conn, attrs), do: credit_or_debit(conn, TransactionGate.debit_type(), attrs)

  defp credit_or_debit(
         conn,
         type,
         %{
           "idempotency_token" => idempotency_token,
           "provider_user_id" => provider_user_id,
           "token_id" => token_id,
           "amount" => amount,
           "account_id" => account_id
         } = attrs
       )
       when idempotency_token != nil and provider_user_id != nil and token_id != nil and
              is_integer(amount) and account_id != nil do
    attrs
    |> Map.put("type", type)
    |> TransactionGate.process_credit_or_debit()
    |> respond_with(:wallets, conn)
  end

  defp credit_or_debit(conn, _type, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with({:ok, transaction, _balances, _token}, :transaction, conn) do
    conn
    |> put_view(TransactionView)
    |> render(:transaction, %{transaction: transaction})
  end

  defp respond_with({:ok, _transaction, wallets, token}, :wallets, conn) do
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

  defp respond_with({:error, _transaction, code, description}, _, conn) do
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
