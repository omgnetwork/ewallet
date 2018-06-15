defmodule AdminAPI.V1.SocketAdminUserAuth do
  @moduledoc """
  This module takes care of authenticating an admin user for websocket connections.
  """
  alias AdminAPI.V1.AdminUserAuth
  alias EWalletDB.{AuthToken, User}

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_token()
  end

  def parse_header(auth, params) do
    case AdminUserAuth.parse_header(auth[:auth_header]) do
      {:ok, user_id, auth_token} ->
        auth
        |> Map.put(:auth_user_id, user_id)
        |> Map.put(:auth_auth_token, auth_token)

      {:error, :invalid_auth_scheme} ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip token auth if it already failed since API key validation or header parsing
  defp authenticate_token(%{assigns: %{authenticated: false}} = auth), do: auth

  defp authenticate_token(auth) do
    user_id = auth[:auth_user_id]
    auth_token = auth[:auth_auth_token]

    case AuthToken.authenticate(user_id, auth_token, :admin_api) do
      %User{} = user ->
        auth
        |> Map.put(:authenticated, :user)
        |> Map.put(:user, user)

      false ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :auth_token_not_found)

      :token_expired ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :auth_token_expired)
    end
  end
end
