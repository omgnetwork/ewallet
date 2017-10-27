defmodule KuberaAPI.V1.UserController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias KuberaDB.User

  def get(conn, %{"provider_user_id" => provider_user_id}) do
    provider_user_id
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
