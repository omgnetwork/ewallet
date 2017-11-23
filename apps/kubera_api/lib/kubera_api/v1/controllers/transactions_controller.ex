defmodule KuberaAPI.V1.TransactionController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias Kubera.{Balance, Transaction}
  plug :put_view, KuberaAPI.V1.BalanceView

  def credit(conn, attrs), do: transfer(conn, Transaction.credit_type, attrs)
  def debit(conn, attrs), do: transfer(conn, Transaction.debit_type, attrs)

  defp transfer(conn, type, %{
    "provider_user_id" => provider_user_id,
    "token_id" => token_id,
    "amount" => amount,
    "metadata" => metadata} = attrs
  )
  when provider_user_id != nil
  and token_id != nil
  and is_integer(amount)
  and metadata != nil
  do
    attrs
    |> Map.put("type", type)
    |> Map.put("idempotency_token", conn.assigns[:idempotency_token])
    |> Transaction.process()
    |> respond_with_balance(conn)
  end
  defp transfer(conn, _type, _attrs), do: handle_error(conn, :invalid_parameter)

  defp respond_with_balance({:ok, user, minted_token}, conn) do
    user
    |> Balance.get(minted_token)
    |> respond(conn)
  end
  defp respond_with_balance({:error, code}, conn), do: handle_error(conn, code)
  defp respond_with_balance({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:ok, addresses}, conn) do
    render(conn, :balances, %{addresses: addresses})
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
