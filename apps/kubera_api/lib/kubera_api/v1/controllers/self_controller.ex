defmodule KuberaAPI.V1.SelfController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias Kubera.Balance
  alias KuberaDB.MintedToken

  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  def get_settings(conn, _attrs) do
    settings = %{minted_tokens: MintedToken.all()}
    render(conn, :settings, settings)
  end

  def get_balances(conn, _attrs) do
    %{"provider_user_id" => conn.assigns.user.provider_user_id}
    |> Balance.all()
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
