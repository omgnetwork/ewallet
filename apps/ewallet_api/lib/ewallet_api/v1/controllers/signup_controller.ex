defmodule EWalletAPI.V1.SignupController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.UserPolicy
  alias EWallet.Web.Inviter
  alias EWalletAPI.VerificationEmail
  alias EWalletDB.Validator

  @doc """
  Signs up a new user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to sign up without an integration with the provider's server.
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signup(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         email when is_binary(email) <- attrs["email"] || :missing_email,
         password when is_binary(password) <- attrs["password"] || :missing_password,
         true <- password == attrs["password_confirmation"] || :passwords_mismatch,
         {:ok, _password} <- Validator.validate_password(password),
         redirect_url when is_binary(redirect_url) <- attrs["redirect_url"] || :no_redirect_url,
         {:ok, invite} <- Inviter.invite(email, redirect_url, VerificationEmail) do
      render(conn, :user, %{user: invite.user})
    else
      :missing_email ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `email` can't be blank"
        )

      :missing_password ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `password` can't be blank"
        )

      {:error, :too_short, min_length: min_length} ->
        handle_error(
          conn,
          :password_too_short,
          "`password` can't be shorter than #{min_length} characters"
        )

      :no_redirect_url ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `redirect_url` can't be blank"
        )

      {:error, :user_already_active} ->
        handle_error(conn, :user_already_active)

      :passwords_mismatch ->
        handle_error(conn, :passwords_mismatch)
    end
  end

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_email(conn, _attrs) do
    conn
  end

  @spec permit(:create, map(), nil) :: :ok | {:error, any()}
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
