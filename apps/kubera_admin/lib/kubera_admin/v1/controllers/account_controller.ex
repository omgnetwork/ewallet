defmodule KuberaAdmin.V1.AccountController do
  use KuberaAdmin, :controller
  import KuberaAdmin.V1.ErrorHandler
  alias KuberaDB.Account

  def all(conn, _attrs) do
    Account.all()
    |> respond(conn)
  end

  def get(conn, %{"id" => id}) do
    id
    |> Account.get_by_id()
    |> respond(conn)
  end

  def create(conn, attrs) do
    attrs
    |> Account.insert()
    |> respond(conn)
  end

  @doc """
  Updates the account if all required parameters are provided.
  """
  def update(conn, %{"id" => id} = attrs) when is_binary(id) and byte_size(id) > 0  do
    id
    |> Account.get_by_id()
    |> update_account(attrs)
    |> respond(conn)
  end
  def update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp update_account(%Account{} = account, attrs) do
    Account.update(account, attrs)
  end
  defp update_account(_, _attrs), do: nil

  # Respond with a list of accounts
  defp respond(accounts, conn) when is_list(accounts) do
    render(conn, :accounts, %{accounts: accounts})
  end
  # Respond with a single account
  defp respond(%Account{} = account, conn) do
    render(conn, :account, %{account: account})
  end
  # Respond when the account is saved successfully
  defp respond({:ok, account}, conn) do
    render(conn, :account, %{account: account})
  end
  # Responds when the account is saved unsucessfully
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  # Responds when the account is not found
  defp respond(nil, conn) do
    handle_error(conn, :account_id_not_found)
  end
end
