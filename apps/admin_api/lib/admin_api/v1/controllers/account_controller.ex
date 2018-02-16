defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  import Bodyguard
  alias EWallet.AccountPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.Account

  @search_fields [{:id, :uuid}, :name, :description]
  @sort_fields [:id, :name, :description]

  @doc """
  Retrieves a list of accounts.
  """
  def all(conn, attrs) do
    Account
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific account by its id.
  """
  def get(conn, %{"id" => id}) do
    id
    |> Account.get()
    |> respond_single(conn)
  end

  @doc """
  Creates a new account.

  The requesting user must have write permission on the given parent account.
  """
  def create(conn, attrs) do
    parent_id = Map.get(attrs, "parent_id")

    case permit(AccountPolicy, :create, conn.assigns.user.id, parent_id) do
      :ok -> do_create(conn, attrs)
      {:error, _} -> handle_error(conn, :user_forbidden)
    end
  end

  defp do_create(conn, attrs) do
    attrs
    |> Account.insert()
    |> respond_single(conn)
  end

  @doc """
  Updates the account if all required parameters are provided.

  The requesting user must have write permission on the given account.
  """
  def update(conn, %{"id" => account_id} = attrs) do
    case permit(AccountPolicy, :update, conn.assigns.user.id, account_id) do
      :ok -> do_update(conn, attrs)
      {:error, :unauthorized} -> handle_error(conn, :user_forbidden)
      {:error, error_code} -> handle_error(conn, error_code)
    end
  end
  def update(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_update(conn, %{"id" => account_id} = attrs)  do
    case Account.get(account_id) do
      %{} = account ->
        account
        |> Account.update(attrs)
        |> respond_single(conn)
      _ ->
        handle_error(conn, :account_id_not_found)
    end
  end
  defp do_update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  @doc """
  Uploads an image as avatar for a specific account.
  """
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    case Account.get(id) do
      nil -> respond_single(nil, conn)
      account ->
        account
        |> Account.store_avatar(attrs)
        |> respond_single(conn)
    end
  end

  # Respond with a list of accounts
  defp respond_multiple(%Paginator{} = paged_accounts, conn) do
    render(conn, :accounts, %{accounts: paged_accounts})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single account
  defp respond_single(%Account{} = account, conn) do
    render(conn, :account, %{account: account})
  end
  # Respond when the account is saved successfully
  defp respond_single({:ok, account}, conn) do
    render(conn, :account, %{account: account})
  end
  # Responds when the account is saved unsucessfully
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  # Responds when the account is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :account_id_not_found)
  end
end
