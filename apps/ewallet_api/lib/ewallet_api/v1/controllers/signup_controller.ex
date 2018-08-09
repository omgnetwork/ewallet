defmodule EWalletAPI.V1.SignupController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.{UserPolicy, VerificationEmail}
  alias EWallet.Web.Inviter

  @doc """
  Signs up a new user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to sign up without an integration with the provider's server.
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signup(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         email when is_binary(email) <- attrs["email"] || :missing_email,
         redirect_url when is_binary(redirect_url) <- attrs["redirect_url"] || :missing_redirect_url,
         {:ok, invite} <- Inviter.invite(email, redirect_url, VerificationEmail) do
      render(conn, :user, %{user: invite.user})
    else
      # Because User.validate_by_roles/2 will validate for `username` and `provider_user_id`
      # if `email` is not provided, we need to handle the missing `email` here.
      :missing_email ->
        handle_error(conn, :invalid_parameter, "Invalid parameter provided. `email` is required")

      :missing_redirect_url ->
        handle_error(conn, :invalid_parameter, "Invalid parameter provided. `redirect_url` is required")

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code} ->
        handle_error(conn, code)
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
