defmodule KuberaAdmin.V1.AccountController do
  use KuberaAdmin, :controller
  import KuberaAdmin.V1.ErrorHandler
  alias Kubera.Web.{SearchParser, SortParser, Paginator}
  alias KuberaDB.Account

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
    |> Account.get_by_id()
    |> respond_single(conn)
  end

  @doc """
  Creates a new account.
  """
  def create(conn, attrs) do
    attrs
    |> Account.insert()
    |> respond_single(conn)
  end

  @doc """
  Updates the account if all required parameters are provided.
  """
  def update(conn, %{"id" => id} = attrs) when is_binary(id) and byte_size(id) > 0  do
    id
    |> Account.get_by_id()
    |> update_account(attrs)
    |> respond_single(conn)
  end
  def update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp update_account(%Account{} = account, attrs) do
    Account.update(account, attrs)
  end
  defp update_account(_, _attrs), do: nil

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
