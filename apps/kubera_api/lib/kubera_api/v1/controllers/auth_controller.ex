defmodule KuberaAPI.V1.AuthController do
  use KuberaAPI, :controller
  import KuberaAPI.V1.ErrorHandler
  alias KuberaDB.{AuthToken, User}
  alias KuberaAPI.V1.Plug.ClientAuth

  @doc """
  Generates a new authentication token for the provider_user_id and returns it.
  """
  def login(conn, %{"provider_user_id" => id})
  when is_binary(id) and byte_size(id) > 0  do
    id
    |> User.get_by_provider_user_id()
    |> generate_token()
    |> respond(conn)
  end
  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp generate_token(nil), do: nil
  defp generate_token(user), do: AuthToken.generate(user)

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    conn
    |> ClientAuth.expire_token()
    |> respond()
  end

  defp respond(nil, conn), do: handle_error(conn, :provider_user_id_not_found)
  defp respond(token, conn), do: render(conn, :auth_token, %{auth_token: token})
  defp respond(conn), do: render(conn, :empty_response, %{})
end
