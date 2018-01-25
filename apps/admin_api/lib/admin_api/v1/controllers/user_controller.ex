defmodule AdminAPI.V1.UserController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.UUID
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.User

  @search_fields [{:id, :uuid}, :username, :provider_user_id]
  @sort_fields [:id, :username, :provider_user_id]

  @doc """
  Retrieves a list of users.
  """
  def all(conn, attrs) do
    User
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific user by its id.
  """
  def get(conn, %{"id" => id}) do
    case UUID.cast(id) do
      {:ok, uuid} ->
        uuid
        |> User.get()
        |> respond_single(conn)
      _ ->
        handle_error(conn, :invalid_parameter, "User ID must be a UUID")
    end
  end

  # Respond with a list of users
  defp respond_multiple(%Paginator{} = paged_users, conn) do
    render(conn, :users, %{users: paged_users})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single user
  defp respond_single(%User{} = user, conn) do
    render(conn, :user, %{user: user})
  end
  # Responds when the user is not found
  defp respond_single(nil, conn) do
    handle_error(conn, :user_id_not_found)
  end
end
