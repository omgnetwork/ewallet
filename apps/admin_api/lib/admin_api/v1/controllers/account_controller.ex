defmodule AdminAPI.V1.AccountController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.MembershipView
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.{Account, Membership, Role, User}

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

  @doc """
  Lists the users that are assigned to the given account.
  """
  def list_users(conn, %{"account_id" => account_id}) do
    list_users(conn, Account.get(account_id, preload: [memberships: :user]))
  end
  def list_users(conn, %Account{} = account) do
    render(conn, MembershipView, :memberships, %{memberships: account.memberships})
  end
  def list_users(conn, nil), do: handle_error(conn, :account_id_not_found)
  def list_users(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Assigns the user to the given account and role.
  """
  def assign_user(conn, %{
    "user_id" => user_id,
    "account_id" => account_id,
    "role_name" => role_name
  }) do
    with %User{} = user <- User.get(user_id) || :user_not_found,
         %Account{} = account <- Account.get(account_id) || :account_not_found,
         %Role{} = role <- Role.get_by_name(role_name) || :role_not_found,
         {:ok, _} <- Membership.assign(user, account, role) do
      render(conn, :empty, %{success: true})
    else
      :user_not_found ->
        handle_error(conn, :invalid_parameter, "The given user id could not be found.")
      :account_not_found ->
        handle_error(conn, :invalid_parameter, "The given account id could not be found.")
      :role_not_found ->
        handle_error(conn, :invalid_parameter, "The given role name could not be found.")
    end
  end
  def assign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  @doc """
  Unassigns the user from the given account.
  """
  def unassign_user(conn, %{
    "user_id" => user_id,
    "account_id" => account_id
  }) do
    with %User{} = user <- User.get(user_id) || :user_not_found,
         %Account{} = account <- Account.get(account_id) || :account_not_found,
         {:ok, _} <- Membership.unassign(user, account) do
      render(conn, :empty, %{success: true})
    else
      :user_not_found ->
        handle_error(conn, :invalid_parameter, "The given user id could not be found.")
      :account_not_found ->
        handle_error(conn, :invalid_parameter, "The given account id could not be found.")
      {:error, :membership_not_found} ->
        handle_error(conn, :invalid_parameter, "The user was not assigned to this account.")
    end
  end
  def unassign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)
end
