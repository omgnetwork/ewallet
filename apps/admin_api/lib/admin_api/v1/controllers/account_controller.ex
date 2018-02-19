defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.AccountPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.Account

  @search_fields [{:id, :uuid}, :name, :description]
  @sort_fields [:id, :name, :description]

  defp permit(action, user_id, account_id) do
    Bodyguard.permit(AccountPolicy, action, user_id, account_id)
  end

  @doc """
  Retrieves a list of accounts.
  """
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns.user.id, nil) do
      accounts =
        Account
        |> SearchParser.to_query(attrs, @search_fields)
        |> SortParser.to_query(attrs, @sort_fields)
        |> Paginator.paginate_attrs(attrs)

      case accounts do
        %Paginator{} = paginator ->
          render(conn, :accounts, %{accounts: paginator})
        {:error, code, description} ->
          handle_error(conn, code, description)
      end
    else
      {:error, code} ->
        handle_error(conn, code)
      nil ->
        handle_error(conn, :account_id_not_found)
    end
  end

  @doc """
  Retrieves a specific account by its id.
  """
  def get(conn, %{"id" => id}) do
    with :ok           <- permit(:get, conn.assigns.user.id, id),
         %{} = account <- Account.get(id)
    do
      render(conn, :account, %{account: account})
    else
      {:error, code} ->
        handle_error(conn, code)
      nil ->
        handle_error(conn, :account_id_not_found)
    end
  end

  @doc """
  Creates a new account.

  The requesting user must have write permission on the given parent account.
  """
  def create(conn, %{"parent_id" => parent_id} = attrs) do
    with :ok            <- permit(:create, conn.assigns.user.id, parent_id),
         {:ok, account} <- Account.insert(attrs)
    do
      render(conn, :account, %{account: account})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
      {:error, code} ->
        handle_error(conn, code)
    end
  end

  @doc """
  Updates the account if all required parameters are provided.

  The requesting user must have write permission on the given account.
  """
  def update(conn, %{"id" => account_id} = attrs) do
    with :ok            <- permit(:update, conn.assigns.user.id, account_id),
         %{} = original <- Account.get(account_id) || {:error, :account_id_not_found},
         {:ok, updated} <- Account.update(original, attrs)
    do
      render(conn, :account, %{account: updated})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
      {:error, code} ->
        handle_error(conn, code)
    end
  end
  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Uploads an image as avatar for a specific account.
  """
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    with :ok           <- permit(:update, conn.assigns.user.id, id),
         %{} = account <- Account.get(id) || {:error, :account_id_not_found},
         %{} = saved   <- Account.store_avatar(account, attrs)
    do
      render(conn, :account, %{account: saved})
    else
      {:error, %{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
      {:error, code} ->
        handle_error(conn, code)
    end
  end
end
