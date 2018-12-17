defmodule AdminAPI.V1.UserAuthController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.UserFetcher
  alias EWallet.Web.{Orchestrator, Originator, V1.AuthTokenOverlay}
  alias EWalletDB.{AuthToken, User}

  @doc """
  Generates a new authentication token for the provider_user_id or id and returns it.
  """
  def login(conn, attrs) do
    with {:ok, %User{} = user} <- UserFetcher.fetch(attrs),
         true <- User.enabled?(user) || {:error, :user_disabled},
         originator <- Originator.extract(conn.assigns),
         {:ok, token} = AuthToken.generate(user, :ewallet_api, originator),
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
    originator = Originator.extract(conn.assigns)
    AuthToken.expire(auth_token, :ewallet_api, originator)

    render(conn, :empty_response, %{})
  end
end
