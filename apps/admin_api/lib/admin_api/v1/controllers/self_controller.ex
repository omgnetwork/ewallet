defmodule AdminAPI.V1.SelfController do
  use AdminAPI, :controller
  alias AdminAPI.V1.AccountView
  alias EWalletDB.Membership

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  @doc """
  Retrieve the list of accounts that the authenticated user has membership in.
  """
  def get_accounts(conn, _attrs) do
    accounts = Membership.user_get_accounts(conn.assigns.user)
    render(conn, AccountView, :accounts, %{accounts: accounts})
  end
end
