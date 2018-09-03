defmodule AdminAPI.V1.UserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias Ecto.Changeset
  alias EWallet.UserPolicy
  alias EWallet.Web.{Paginator, SearchParser, SortParser}
  alias EWalletDB.{Account, AccountUser, User, UserQuery}

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  # `@mapped_fields` don't affect them.
  @search_fields [:id, :username, :provider_user_id]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :username, :provider_user_id, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of users.
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil) do
      # Get all users since everyone can access them
      User
      |> UserQuery.where_end_user()
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      User
      |> UserQuery.where_end_user()
      |> Account.query_all_users([account.uuid])
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      User
      |> UserQuery.where_end_user()
      |> Account.query_all_users(descendant_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec do_all(Ecto.Queryable.t(), map(), Plug.Conn.t()) :: Plug.Conn.t()
  defp do_all(query, attrs, conn) do
    query
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific user by its id.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => id}) do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def get(conn, %{"provider_user_id" => id})
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get_by_provider_user_id(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, user) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def get(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end

  # When creating a new user, we need to link it with the current account
  # defined in the key or in the auth token so that the user can access it
  # even if that user hasn't had any transaction with the account yet (since
  # that's how users and accounts are linked together).
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         {:ok, user} <- User.insert(attrs),
         %Account{} = account <- AccountHelper.get_current_account(conn),
         {:ok, _account_user} <- AccountUser.link(account.uuid, user.uuid) do
      respond_single(user, conn)
    else
      error -> respond_single(error, conn)
    end
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  # Pattern matching for required params because changeset will treat
  # missing param as not need to update.
  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(
        conn,
        %{
          "id" => id,
          "username" => _
        } = attrs
      )
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, user) do
      user
      |> User.update(attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def update(
        conn,
        %{
          "provider_user_id" => id,
          "username" => _
        } = attrs
      )
      when is_binary(id) and byte_size(id) > 0 do
    with %User{} = user <- User.get_by_provider_user_id(id) || {:error, :unauthorized},
         :ok <- permit(:update, conn.assigns, user) do
      user
      |> User.update(attrs)
      |> respond_single(conn)
    else
      error -> respond_single(error, conn)
    end
  end

  def update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  # Respond with a list of users
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, :users, %{users: paged_users})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single user
  defp respond_single(%User{} = user, conn), do: render(conn, :user, %{user: user})

  # Responds when the user is not found
  defp respond_single(nil, conn), do: handle_error(conn, :user_id_not_found)

  # Responds when user is saved successfully
  defp respond_single({:ok, user}, conn) do
    respond_single(user, conn)
  end

  defp respond_single({:error, %Changeset{} = changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code}, conn) do
    handle_error(conn, code)
  end

  @spec permit(:all | :create | :get | :update, map(), %Account{} | %User{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
