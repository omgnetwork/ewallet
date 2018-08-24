defmodule EWalletAPI.V1.SelfController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.BalanceFetcher
  alias EWalletDB.Token

  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  def get_settings(conn, _attrs) do
    settings = %{tokens: Token.all()}
    render(conn, :settings, settings)
  end

  def get_wallets(conn, _attrs) do
    %{"user_id" => conn.assigns.user.id}
    |> BalanceFetcher.all()
    |> respond(conn)
  end

  defp respond({:ok, addresses}, conn) do
    render(conn, :wallets, %{addresses: [addresses]})
  end

  defp respond({:error, code}, conn), do: handle_error(conn, code)
end
