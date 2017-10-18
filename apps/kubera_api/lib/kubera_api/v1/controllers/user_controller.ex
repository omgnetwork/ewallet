defmodule KuberaAPI.V1.UserController do
  use KuberaAPI, :controller
  alias KuberaAPI.V1.ErrorView
  alias KuberaDB.User

  def get(conn, %{"id" => id}) do
    id
    |> User.get()
    |> respond(conn)
  end

  def get(conn, %{"provider_user_id" => provider_user_id}) do
    provider_user_id
    |> User.get_by_provider_user_id()
    |> respond(conn)
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
    |> put_status(:ok)
    |> render("user.json", %{user: user})
  end

  # Responds when user is saved unsucessfully
  defp respond({:error, _changeset}, conn) do
    conn
    |> put_status(:bad_request)
    |> render(ErrorView, "error.json", %{code: "invalid_data", message: "Invalid user data"})
  end

  # Responds when user is not found
  defp respond(nil, conn) do
    conn
    |> put_status(:not_found)
    |> render(ErrorView, "error.json", %{code: "user_not_found", message: "User not found"})
  end
end
