defmodule EWalletAPI.V1.SelfController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.{Orchestrator, V1.WalletOverlay}
  alias EWallet.BalanceFetcher
  alias EWalletDB.Token

  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  def get_settings(conn, _attrs) do
    settings = %{tokens: Token.all()}
    render(conn, :settings, settings)
  end

  def get_wallets(conn, attrs) do
    with {:ok, wallet} <- BalanceFetcher.all(%{"user_id" => conn.assigns.user.id}) do
      {:ok, wallets} = Orchestrator.all([wallet], WalletOverlay, attrs)
      render(conn, :wallets, %{wallets: wallets})
    else
      {:error, code} -> handle_error(conn, code)
    end
  end
end
