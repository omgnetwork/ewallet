defmodule AdminAPI.V1.SelfController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{AccountView, UserView}
  alias EWallet.Web.Paginator
  alias EWalletDB.{Account, User}

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    render(conn, :user, %{user: conn.assigns.user})
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  def update(conn, attrs) do
    case User.update_without_password(conn.assigns.user, attrs) do
      {:ok, %User{} = user} ->
        render(conn, :user, %{user: user})

      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Uploads an image as avatar for the current user.
  """
  def upload_avatar(conn, %{"avatar" => _} = attrs) do
    case conn.assigns.user do
      nil ->
        respond_single(nil, conn)

      user ->
        user
        |> User.store_avatar(attrs)
        |> respond_single(conn)
    end
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(conn, _attrs) do
    case User.get_account(conn.assigns.user) do
      %Account{} = account ->
        render(conn, AccountView, :account, %{account: account})

      nil ->
        handle_error(conn, :user_account_not_found)
    end
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

  # Respond with a single admin
  defp respond_single(%User{} = user, conn) do
    render(conn, UserView, :user, %{user: user})
  end

  # Responds when the given params were invalid
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  # Responds when the admin is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :user_id_not_found)
  end
end
