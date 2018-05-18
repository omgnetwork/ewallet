defmodule EWalletAPI.V1.TransferController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{BalanceFetcher, TransactionGate}

  plug(:put_view, EWalletAPI.V1.WalletView)

  def transfer(
        conn,
        %{
          "from_address" => from_address,
          "to_address" => to_address,
          "token_id" => token_id,
          "amount" => amount
        } = attrs
      )
      when from_address != nil
      when to_address != nil and token_id != nil and is_integer(amount) do
    attrs
    |> Map.put("idempotency_token", conn.assigns[:idempotency_token])
    |> TransactionGate.process_with_addresses()
    |> respond_with_wallets(conn)
  end

  def transfer(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  def credit(conn, attrs), do: credit_or_debit(conn, TransactionGate.credit_type(), attrs)
  def debit(conn, attrs), do: credit_or_debit(conn, TransactionGate.debit_type(), attrs)

  defp credit_or_debit(
         conn,
         type,
         %{"provider_user_id" => provider_user_id, "token_id" => token_id, "amount" => amount} =
           attrs
       )
       when provider_user_id != nil and token_id != nil and is_integer(amount) do
    attrs
    |> Map.put("type", type)
    |> Map.put("idempotency_token", conn.assigns[:idempotency_token])
    |> TransactionGate.process_credit_or_debit()
    |> respond_with_wallets(conn)
  end

  defp credit_or_debit(conn, _type, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with_wallets({:ok, _transfer, wallets, minted_token}, conn) do
    wallets =
      Enum.map(wallets, fn wallet ->
        case BalanceFetcher.get(minted_token.id, wallet) do
          {:ok, address} -> address
          error -> error
        end
      end)

    case Enum.find(wallets, fn e -> match?({:error, _code, _description}, e) end) do
      nil -> respond({:ok, wallets}, conn)
      error -> error
    end
  end

  defp respond_with_wallets({:error, code}, conn), do: handle_error(conn, code)

  defp respond_with_wallets({:error, _transfer, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:ok, wallets}, conn) do
    render(conn, :wallets, %{wallets: wallets})
  end

  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
