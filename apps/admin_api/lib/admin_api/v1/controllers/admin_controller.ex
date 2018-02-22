defmodule AdminAPI.V1.AdminController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.UUID
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias AdminAPI.V1.UserView
  alias EWalletDB.{User, UserQuery}

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
  @search_fields [{:id, :uuid}, :email]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :email, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of admins.
  """
  def all(conn, attrs) do
    User
    |> UserQuery.where_has_membership()
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific admin by its id.
  """
  def get(conn, %{"id" => id}) do
    case UUID.cast(id) do
      {:ok, uuid} ->
        query = UserQuery.where_has_membership()

        uuid
        |> User.get(query)
        |> respond_single(conn)
      _ ->
        handle_error(conn, :invalid_parameter, "Admin ID must be a UUID")
    end
  end

  @doc """
  Uploads an image as avatar for a specific user.
  """
  def upload_avatar(conn, %{"id" => id, "avatar" => _} = attrs) do
    case UUID.cast(id) do
      {:ok, uuid} ->
        case User.get(uuid, UserQuery.where_has_membership()) do
          nil -> respond_single(nil, conn)
          user ->
            user
            |> User.store_avatar(attrs)
            |> respond_single(conn)
        end
      _ ->
        handle_error(conn, :invalid_parameter, "Admin ID must be a UUID")
    end
  end

  # Respond with a list of admins
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, UserView, :users, %{users: paged_users})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
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
