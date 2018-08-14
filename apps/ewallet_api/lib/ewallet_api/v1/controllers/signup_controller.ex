defmodule EWalletAPI.V1.SignupController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.UserPolicy
  alias EWallet.Web.{Inviter, Preloader}
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.Invite

  @doc """
  Signs up a new user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to sign up without an integration with the provider's server.
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signup(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         email when is_binary(email) <- attrs["email"] || {:error, :missing_email},
         redirect_url when is_binary(redirect_url) <-
           attrs["redirect_url"] || {:error, :missing_redirect_url},
         {:ok, invite} <- Inviter.invite(email, redirect_url, VerificationEmail) do
      render(conn, :user, %{user: invite.user})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_email(conn, attrs) do
    with email when is_binary(email) <- attrs["email"] || {:error, :missing_email},
         token when is_binary(token) <- attrs["token"] || {:error, :missing_token},
         password when is_binary(password) <- attrs["password"] || {:error, :missing_password},
         true <- password == attrs["password_confirmation"] || {:error, :passwords_mismatch},
         %Invite{} = invite <- Invite.get(email, token) || {:error, :email_token_not_found},
         {:ok, invite} <- Preloader.preload_one(invite, :user),
         {:ok, _} <- Invite.accept(invite, password) do
      render(conn, :user, %{user: invite.user})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  @spec permit(:create, map(), nil) :: :ok | {:error, any()}
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
