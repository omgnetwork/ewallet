defmodule KuberaAPI.V1.BalanceController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias Kubera.{Balance, Transaction}

  def all(conn, %{"provider_user_id" => _} = attrs) do
    attrs
    |> Balance.all()
    |> respond(conn)
  end

  def all(conn, %{"address" => _} = attrs) do
    attrs
    |> Balance.all()
    |> respond(conn)
  end
  def all(conn, _params), do: handle_error(conn, :invalid_parameter)

  def credit(conn, %{"provider_user_id" => provider_user_id, "symbol" => _,
                     "amount" => amount, "metadata" => _} = attrs)
                     when is_integer(amount) do
    attrs
    |> Transaction.init_credit()
    |> process_transaction(provider_user_id, conn)
  end
  def credit(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end

  def debit(conn, %{"provider_user_id" => provider_user_id, "symbol" => _,
                    "amount" => amount, "metadata" => _} = attrs)
                    when is_integer(amount) do
    attrs
    |> Transaction.init_debit()
    |> process_transaction(provider_user_id, conn)
  end
  def debit(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end

  defp process_transaction({:ok, transaction}, provider_user_id, conn) do
    transaction
    |> Transaction.create()
    |> respond_with_balances(provider_user_id, conn)
  end
  defp process_transaction({:error, code}, _, conn) do
    handle_error(conn, code)
  end

  defp respond_with_balances({:error, code, desc}, _, conn) do
    handle_error(conn, code, desc)
  end
  defp respond_with_balances(a, provider_user_id, conn) do
    %{"provider_user_id" => provider_user_id}
    |> Balance.all()
    |> respond(conn)
  end

  defp respond({:ok, balances}, conn) do
    render(conn, :balances, %{balances: balances})
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
