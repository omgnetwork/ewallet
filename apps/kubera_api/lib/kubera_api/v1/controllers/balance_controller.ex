defmodule KuberaAPI.V1.BalanceController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias Kubera.Balance

  def all(conn, %{"provider_user_id" => provider_user_id} = attrs)
    when provider_user_id != nil,
  do: get_all(conn, attrs)
  def all(conn, %{"address" => address} = attrs)
    when address != nil,
  do: get_all(conn, attrs)
  def all(conn, _params), do: handle_error(conn, :invalid_parameter)

  defp get_all(conn, attrs), do: attrs |> Balance.all() |> respond(conn)

  defp respond({:ok, addresses}, conn) do
    render(conn, :balances, %{addresses: [addresses]})
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
