defmodule AdminAPI.V1.UserAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.UserFetcher
  alias EWallet.Web.{Orchestrator, V1.AuthTokenOverlay}
  alias EWalletDB.{AuthToken, User}

  @doc """
  Generates a new authentication token for the provider_user_id or id and returns it.
  """
  def login(conn, attrs) do
    with {:ok, %User{} = user} <- UserFetcher.fetch(attrs),
         true <- User.enabled?(user) || {:error, :user_disabled},
         {:ok, token} = AuthToken.generate(user, :ewallet_api),
         {:ok, token} = Orchestrator.one(token, AuthTokenOverlay, attrs) do
      render(conn, :auth_token, %{auth_token: token})
    else
      {:error, :invalid_parameter} ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `id` or `provider_user_id` is required."
        )

      {:error, error} ->
        handle_error(conn, error)
    end
  end

  @doc """
  Invalidates the authentication token used in this request.
  """
  def logout(conn, %{"auth_token" => auth_token}) do
    auth_token |> AuthToken.expire(:ewallet_api)

    render(conn, :empty_response, %{})
  end
end
