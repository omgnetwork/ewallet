defmodule AdminAPI.V1.SelfController do
  use AdminAPI, :controller
  alias AdminAPI.V1.AccountView
  alias EWallet.Web.Paginator
  alias EWalletDB.User

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(conn, _attrs) do
    account = User.get_account(conn.assigns.user)
    render(conn, AccountView, :account, %{account: account})
  end

  @doc """
  Retrieves the list of accounts that the authenticated user has membership in.
  """
  def get_accounts(conn, attrs) do
    accounts =
      conn.assigns.user
      |> User.query_accounts()
      |> Paginator.paginate_attrs(attrs)

    render(conn, AccountView, :accounts, %{accounts: accounts})
  end
end
