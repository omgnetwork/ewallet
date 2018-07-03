defmodule AdminAPI.V1.UserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.User

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
  def all(conn, attrs) do
    # Get all users for current account
    User
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific user by its id.
  """
  def get(conn, %{"id" => id}) do
    id
    |> User.get()
    |> respond_single(conn)
  end

  def get(conn, %{"provider_user_id" => id})
      when is_binary(id) and byte_size(id) > 0 do
    id
    |> User.get_by_provider_user_id()
    |> respond(conn)
  end

  def get(conn, _params) do
    handle_error(conn, :invalid_parameter)
  end

  def create(conn, attrs) do
    attrs
    |> User.insert()
    |> respond(conn)
  end

  @doc """
  Updates the user if all required parameters are provided.
  """
  # Pattern matching for required params because changeset will treat
  # missing param as not need to update.
  def update(
        conn,
        %{
          "provider_user_id" => id,
          "username" => _
        } = attrs
      )
      when is_binary(id) and byte_size(id) > 0 do
    id
    |> User.get_by_provider_user_id()
    |> update_user(attrs)
    |> respond(conn)
  end

  def update(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp update_user(%User{} = user, attrs), do: User.update(user, attrs)
  defp update_user(_, _attrs), do: nil

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
  defp respond({:ok, user}, conn) do
    respond(user, conn)
  end

  # Responds with valid user data
  defp respond(%User{} = user, conn) do
    conn
    |> render(:user, %{user: user})
  end

  # Responds when user is saved unsucessfully
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  # Responds when user is not found
  defp respond(nil, conn) do
    handle_error(conn, :provider_user_id_not_found)
  end
end
