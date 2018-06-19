defmodule AdminAPI.V1.AdminUserAuth do
  @moduledoc """
  This module takes care of authenticating an admin user for websocket connections.
  """
  alias EWalletDB.{AuthToken, User}

  def authenticate(auth) do
    auth
    |> parse_header()
    |> authenticate_token()
  end

  defp parse_header(auth) do
    with header when not is_nil(header) <- auth[:auth_header],
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         [user_id, auth_token] <- String.split(decoded, ":", parts: 2) do
      auth
      |> Map.put(:auth_user_id, user_id)
      |> Map.put(:auth_auth_token, auth_token)
    else
      _ ->
        auth
        |> Map.put(:authenticated, false)
        |> Map.put(:auth_error, :invalid_auth_scheme)
    end
  end

  # Skip token auth if it already failed since API key validation or header parsing
  defp authenticate_token(%{authenticated: false} = auth), do: auth

  defp authenticate_token(auth) do
    user_id = auth[:auth_user_id]
    auth_token = auth[:auth_auth_token]

    case AuthToken.authenticate(user_id, auth_token, :admin_api) do
      %User{} = admin_user ->
        auth
        |> Map.put(:authenticated, true)
        |> Map.put(:admin_user, admin_user)

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
