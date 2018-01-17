defmodule AdminAPI.V1.AdminController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.UUID
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias AdminAPI.V1.UserView
  alias EWalletDB.{User, UserQuery}

  @search_fields [{:id, :uuid}, :email]
  @sort_fields [:id, :email]

  @doc """
  Retrieves a list of admins.
  """
  def all(conn, attrs) do
    User
    |> UserQuery.where_has_membership()
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields)
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
  # Responds when the admin is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :user_id_not_found)
  end
end
