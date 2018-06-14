defmodule AdminAPI.V1.AuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.V1.ClientAuth
  alias EWalletDB.{AuthToken, User}

  @doc """
  Generates a new authentication token for the provider_user_id and returns it.
  """
  def login(conn, %{"provider_user_id" => id})
      when is_binary(id) and byte_size(id) > 0 do
    id
    |> User.get_by_provider_user_id()
    |> generate_token()
    |> respond(conn)
  end

  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp generate_token(nil), do: {:error, :provider_user_id_not_found}
  defp generate_token(user), do: AuthToken.generate(user, :ewallet_api)

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, _attrs) do
    conn.private[:auth_auth_token]
    |> ClientAuth.expire_token(:ewallet_api)
    |> respond()
  end

  defp respond({:ok, token}, conn), do: render(conn, :auth_token, %{auth_token: token})
  defp respond({:error, code}, conn), do: handle_error(conn, code)
  defp respond(conn), do: render(conn, :empty_response, %{})
end
