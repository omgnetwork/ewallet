defmodule AdminAPI.V1.UserAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.{Orchestrator, V1.AuthTokenOverlay}
  alias EWalletDB.{AuthToken, User}

  @doc """
  Generates a new authentication token for the provider_user_id and returns it.
  """
  def login(conn, %{"id" => id} = attrs)
      when is_binary(id) and byte_size(id) > 0 do
    id
    |> User.get()
    |> generate_token()
    |> respond(conn, attrs)
  end

  def login(conn, %{"provider_user_id" => id} = attrs)
      when is_binary(id) and byte_size(id) > 0 do
    id
    |> User.get_by_provider_user_id()
    |> generate_token()
    |> respond(conn, attrs)
  end

  def login(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  defp generate_token(nil), do: {:error, :provider_user_id_not_found}
  defp generate_token(user), do: AuthToken.generate(user, :ewallet_api)

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, %{"auth_token" => auth_token}) do
    auth_token |> AuthToken.expire(:ewallet_api)

    respond(conn)
  end

  defp respond({:ok, token}, conn, attrs) do
    {:ok, token} = Orchestrator.one(token, AuthTokenOverlay, attrs)
    render(conn, :auth_token, %{auth_token: token})
  end
  defp respond({:error, code}, conn, _), do: handle_error(conn, code)
  defp respond(conn), do: render(conn, :empty_response, %{})
end
