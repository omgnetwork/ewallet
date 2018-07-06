defmodule AdminAPI.V1.SelfController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.{AccountView, UserView, AccountHelper}
  alias EWallet.Web.Paginator
  alias EWalletDB.{Account, User}
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}
  alias Ecto.Changeset

  @mapped_fields %{
    "created_at" => "inserted_at"
  }
  @preload_fields [:categories]
  @search_fields [:id, :name, :description]
  @sort_fields [:id, :name, :description, :inserted_at, :updated_at]

  @doc """
  Retrieves the currently authenticated user.
  """
  def get(conn, _attrs) do
    with {:ok, current_user} <- permit(:get, conn.assigns) do
      render(conn, :user, %{user: current_user})
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  def update(conn, attrs) do
    with {:ok, current_user} <- permit(:update, conn.assigns),
         {:ok, user} <- User.update_without_password(current_user, attrs) do
      respond_single(user, conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Uploads an image as avatar for the current user.
  """
  def upload_avatar(conn, %{"avatar" => _} = attrs) do
    with {:ok, current_user} <- permit(:update, conn.assigns) do
      current_user
      |> User.store_avatar(attrs)
      |> respond_single(conn)
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(conn, _attrs) do
    with {:ok, current_user} <- permit(:update, conn.assigns),
         %Account{} = acc <- User.get_account(current_user) || :user_account_not_found do
      render(conn, AccountView, :account, %{account: acc})
    else
      error ->
        respond_single(error, conn)
    end
  end

  @doc """
  Retrieves the list of accounts that the authenticated user has membership in.
  """
  def get_accounts(conn, attrs) do
    with {:ok, current_user} <- permit(:update, conn.assigns),
         account_uuids <- AccountHelper.get_accessible_account_uuids(%{admin_user: current_user}) do
      accounts =
        Account
        |> Account.where_in(account_uuids)
        |> Preloader.to_query(@preload_fields)
        |> SearchParser.to_query(attrs, @search_fields, @mapped_fields)
        |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
        |> Paginator.paginate_attrs(attrs)

      render(conn, AccountView, :accounts, %{accounts: accounts})
    else
      error ->
        respond_single(error, conn)
    end
  end

  # Respond with a single admin
  defp respond_single(%User{} = user, conn) do
    render(conn, UserView, :user, %{user: user})
  end

  # Responds when the given params were invalid
  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single(error_code, conn) when is_atom(error_code) do
    handle_error(conn, error_code)
  end

  # Responds when the admin is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :user_id_not_found)
  end

  @spec permit(:all | :create | :get | :update, map()) ::
          {:ok, User.t()} | {:error, any()} | no_return()
  defp permit(_action, %{admin_user: admin_user}) do
    {:ok, admin_user}
  end

  defp permit(_action, %{key: _key}) do
    :access_key_unauthorized
  end
end
