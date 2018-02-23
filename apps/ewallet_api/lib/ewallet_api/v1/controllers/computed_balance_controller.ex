defmodule EWalletAPI.V1.ComputedBalanceController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.ComputedBalanceFetcher

  def all(conn, %{"provider_user_id" => provider_user_id} = attrs)
    when provider_user_id != nil,
  do: get_all(conn, attrs)
  def all(conn, %{"address" => address} = attrs)
    when address != nil,
  do: get_all(conn, attrs)
  def all(conn, _params), do: handle_error(conn, :invalid_parameter)

  defp get_all(conn, attrs) do
    attrs
    |> ComputedBalanceFetcher.all()
    |> respond(conn)
  end

  defp respond({:ok, addresses}, conn) do
    render(conn, :balances, %{addresses: [addresses]})
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
