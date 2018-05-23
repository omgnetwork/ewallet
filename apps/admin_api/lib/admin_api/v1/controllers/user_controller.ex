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

  # Respond with a list of users
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, :users, %{users: paged_users})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single user
  defp respond_single(%User{} = user, conn), do: render(conn, :user, %{user: user})
  # Responds when the given params were invalid
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  # Responds when the user is not found
  defp respond_single(nil, conn), do: handle_error(conn, :user_id_not_found)
end
